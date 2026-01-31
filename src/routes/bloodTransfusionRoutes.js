const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY
);

// Middleware to verify authentication
const authenticateUser = async (req, res, next) => {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
        return res.status(401).json({ error: 'No authorization token provided' });
    }
    
    try {
        const { data: { user }, error } = await supabase.auth.getUser(token);
        
        if (error || !user) {
            return res.status(401).json({ error: 'Invalid or expired token' });
        }
        
        req.user = user;
        next();
    } catch (error) {
        console.error('Authentication error:', error);
        res.status(500).json({ error: 'Authentication failed' });
    }
};

// POST /api/blood-transfusion/start - Start a new transfusion
router.post('/start', authenticateUser, async (req, res) => {
    try {
        const {
            taskId,
            patientId,
            pouchVolumeMl,
            dropFactor,
            dropRatePerMinute,
            startTime,
            expectedEndTime,
            alertThresholdMinutes,
            notes
        } = req.body;
        
        // Validation
        if (!taskId || !patientId || !pouchVolumeMl || !dropFactor || !dropRatePerMinute) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        if (pouchVolumeMl < 100 || pouchVolumeMl > 1000) {
            return res.status(400).json({ error: 'Volume must be between 100-1000 ml' });
        }
        
        if (dropRatePerMinute < 20 || dropRatePerMinute > 100) {
            return res.status(400).json({ error: 'Drop rate must be between 20-100 drops/min' });
        }
        
        // Insert transfusion record
        const { data, error } = await supabase
            .from('blood_transfusions')
            .insert({
                task_id: taskId,
                patient_id: patientId,
                caregiver_id: req.user.id,
                pouch_volume_ml: pouchVolumeMl,
                drop_factor: dropFactor,
                drop_rate_per_minute: dropRatePerMinute,
                start_time: startTime || new Date().toISOString(),
                expected_end_time: expectedEndTime,
                alert_threshold_minutes: alertThresholdMinutes || 15,
                status: 'IN_PROGRESS',
                notes: notes
            })
            .select()
            .single();
        
        if (error) {
            console.error('Error starting transfusion:', error);
            return res.status(500).json({ error: 'Failed to start transfusion' });
        }
        
        res.json({
            success: true,
            transfusion: data
        });
        
    } catch (error) {
        console.error('Error in start transfusion:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// PATCH /api/blood-transfusion/:id/pause - Pause a transfusion
router.patch('/:id/pause', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { pausedAt } = req.body;
        
        const { data, error } = await supabase
            .from('blood_transfusions')
            .update({
                status: 'PAUSED',
                paused_at: pausedAt || new Date().toISOString()
            })
            .eq('id', id)
            .eq('caregiver_id', req.user.id)
            .select()
            .single();
        
        if (error) {
            console.error('Error pausing transfusion:', error);
            return res.status(500).json({ error: 'Failed to pause transfusion' });
        }
        
        res.json({
            success: true,
            transfusion: data
        });
        
    } catch (error) {
        console.error('Error in pause transfusion:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// PATCH /api/blood-transfusion/:id/resume - Resume a transfusion
router.patch('/:id/resume', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { pauseDurationMs } = req.body;
        
        const { data, error } = await supabase
            .from('blood_transfusions')
            .update({
                status: 'IN_PROGRESS',
                paused_at: null,
                pause_duration_ms: pauseDurationMs || 0
            })
            .eq('id', id)
            .eq('caregiver_id', req.user.id)
            .select()
            .single();
        
        if (error) {
            console.error('Error resuming transfusion:', error);
            return res.status(500).json({ error: 'Failed to resume transfusion' });
        }
        
        res.json({
            success: true,
            transfusion: data
        });
        
    } catch (error) {
        console.error('Error in resume transfusion:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// PATCH /api/blood-transfusion/:id/complete - Complete a transfusion
router.patch('/:id/complete', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { actualEndTime, notes, complications } = req.body;
        
        const { data, error } = await supabase
            .from('blood_transfusions')
            .update({
                status: 'COMPLETED',
                actual_end_time: actualEndTime || new Date().toISOString(),
                notes: notes,
                complications: complications
            })
            .eq('id', id)
            .eq('caregiver_id', req.user.id)
            .select()
            .single();
        
        if (error) {
            console.error('Error completing transfusion:', error);
            return res.status(500).json({ error: 'Failed to complete transfusion' });
        }
        
        res.json({
            success: true,
            transfusion: data
        });
        
    } catch (error) {
        console.error('Error in complete transfusion:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// PATCH /api/blood-transfusion/:id/stop-early - Stop transfusion early
router.patch('/:id/stop-early', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { reason, actualEndTime } = req.body;
        
        if (!reason) {
            return res.status(400).json({ error: 'Reason is required' });
        }
        
        const { data, error } = await supabase
            .from('blood_transfusions')
            .update({
                status: 'STOPPED_EARLY',
                actual_end_time: actualEndTime || new Date().toISOString(),
                complications: reason
            })
            .eq('id', id)
            .eq('caregiver_id', req.user.id)
            .select()
            .single();
        
        if (error) {
            console.error('Error stopping transfusion:', error);
            return res.status(500).json({ error: 'Failed to stop transfusion' });
        }
        
        res.json({
            success: true,
            transfusion: data
        });
        
    } catch (error) {
        console.error('Error in stop early transfusion:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/blood-transfusion/:id/progress - Record progress snapshot
router.post('/:id/progress', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const {
            elapsedTimeMs,
            remainingTimeMs,
            dropsAdministered,
            volumeAdministeredMl,
            progressPercentage
        } = req.body;
        
        // Verify transfusion belongs to user
        const { data: transfusion } = await supabase
            .from('blood_transfusions')
            .select('id')
            .eq('id', id)
            .eq('caregiver_id', req.user.id)
            .single();
        
        if (!transfusion) {
            return res.status(404).json({ error: 'Transfusion not found' });
        }
        
        const { data, error } = await supabase
            .from('blood_transfusion_progress')
            .insert({
                transfusion_id: id,
                elapsed_time_ms: elapsedTimeMs,
                remaining_time_ms: remainingTimeMs,
                drops_administered: dropsAdministered,
                volume_administered_ml: volumeAdministeredMl,
                progress_percentage: progressPercentage
            })
            .select()
            .single();
        
        if (error) {
            console.error('Error recording progress:', error);
            return res.status(500).json({ error: 'Failed to record progress' });
        }
        
        res.json({
            success: true,
            progress: data
        });
        
    } catch (error) {
        console.error('Error in record progress:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/blood-transfusion/:id/note - Add a note
router.post('/:id/note', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { note, noteType } = req.body;
        
        if (!note) {
            return res.status(400).json({ error: 'Note is required' });
        }
        
        // Verify transfusion belongs to user
        const { data: transfusion } = await supabase
            .from('blood_transfusions')
            .select('id')
            .eq('id', id)
            .eq('caregiver_id', req.user.id)
            .single();
        
        if (!transfusion) {
            return res.status(404).json({ error: 'Transfusion not found' });
        }
        
        const { data, error } = await supabase
            .from('blood_transfusion_notes')
            .insert({
                transfusion_id: id,
                note: note,
                note_type: noteType || 'GENERAL'
            })
            .select()
            .single();
        
        if (error) {
            console.error('Error adding note:', error);
            return res.status(500).json({ error: 'Failed to add note' });
        }
        
        res.json({
            success: true,
            note: data
        });
        
    } catch (error) {
        console.error('Error in add note:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST /api/blood-transfusion/:id/alert - Record an alert
router.post('/:id/alert', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        const { alertType, alertMessage } = req.body;
        
        if (!alertType || !alertMessage) {
            return res.status(400).json({ error: 'Alert type and message are required' });
        }
        
        // Verify transfusion belongs to user
        const { data: transfusion } = await supabase
            .from('blood_transfusions')
            .select('id')
            .eq('id', id)
            .eq('caregiver_id', req.user.id)
            .single();
        
        if (!transfusion) {
            return res.status(404).json({ error: 'Transfusion not found' });
        }
        
        const { data, error } = await supabase
            .from('blood_transfusion_alerts')
            .insert({
                transfusion_id: id,
                alert_type: alertType,
                alert_message: alertMessage
            })
            .select()
            .single();
        
        if (error) {
            console.error('Error recording alert:', error);
            return res.status(500).json({ error: 'Failed to record alert' });
        }
        
        res.json({
            success: true,
            alert: data
        });
        
    } catch (error) {
        console.error('Error in record alert:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/blood-transfusion/:id - Get transfusion details
router.get('/:id', authenticateUser, async (req, res) => {
    try {
        const { id } = req.params;
        
        const { data, error } = await supabase
            .from('blood_transfusions')
            .select(`
                *,
                notes:blood_transfusion_notes(*),
                alerts:blood_transfusion_alerts(*),
                progress:blood_transfusion_progress(*)
            `)
            .eq('id', id)
            .eq('caregiver_id', req.user.id)
            .single();
        
        if (error) {
            console.error('Error fetching transfusion:', error);
            return res.status(404).json({ error: 'Transfusion not found' });
        }
        
        res.json({
            success: true,
            transfusion: data
        });
        
    } catch (error) {
        console.error('Error in get transfusion:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/blood-transfusion/history - Get transfusion history
router.get('/history/all', authenticateUser, async (req, res) => {
    try {
        const { limit = 50, offset = 0 } = req.query;
        
        const { data, error, count } = await supabase
            .from('blood_transfusion_summary')
            .select('*', { count: 'exact' })
            .eq('caregiver_id', req.user.id)
            .order('start_time', { ascending: false })
            .range(offset, offset + limit - 1);
        
        if (error) {
            console.error('Error fetching history:', error);
            return res.status(500).json({ error: 'Failed to fetch history' });
        }
        
        res.json({
            success: true,
            transfusions: data,
            total: count
        });
        
    } catch (error) {
        console.error('Error in get history:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/blood-transfusion/active - Get active transfusions
router.get('/active/all', authenticateUser, async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('blood_transfusions')
            .select('*')
            .eq('caregiver_id', req.user.id)
            .in('status', ['IN_PROGRESS', 'PAUSED'])
            .order('start_time', { ascending: false });
        
        if (error) {
            console.error('Error fetching active transfusions:', error);
            return res.status(500).json({ error: 'Failed to fetch active transfusions' });
        }
        
        res.json({
            success: true,
            transfusions: data
        });
        
    } catch (error) {
        console.error('Error in get active transfusions:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
