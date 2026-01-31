const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const config = require('../config/config');

const supabase = createClient(config.supabase.url, config.supabase.serviceKey);

// Create patient with medicines
router.post('/patients', async (req, res) => {
  try {
    const { userId, name, age, diseaseCondition, medicines } = req.body;

    // Validate input
    if (!userId || !name || !age || !diseaseCondition) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Insert patient
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .insert({
        user_id: userId,
        name,
        age,
        disease_condition: diseaseCondition
      })
      .select()
      .single();

    if (patientError) {
      console.error('Error creating patient:', patientError);
      return res.status(500).json({ error: 'Failed to create patient' });
    }

    // Insert medicines if provided
    if (medicines && medicines.length > 0) {
      const medicineRecords = medicines.map(med => ({
        patient_id: patient.id,
        medicine_name: med.medicineName,
        photo_url: med.photoUrl || null
      }));

      const { error: medicineError } = await supabase
        .from('patient_medicines')
        .insert(medicineRecords);

      if (medicineError) {
        console.error('Error creating medicines:', medicineError);
        // Continue anyway, patient is created
      }
    }

    res.json({ patient });
  } catch (error) {
    console.error('Error in POST /patients:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create SOP with steps
router.post('/sops', async (req, res) => {
  try {
    const {
      userId,
      patientId,
      title,
      description,
      steps,
      rawGeminiResponse,
      createdBy
    } = req.body;

    // Validate input
    if (!userId || !patientId || !title || !steps || !createdBy) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Insert SOP
    const { data: sop, error: sopError } = await supabase
      .from('sops')
      .insert({
        user_id: userId,
        patient_id: patientId,
        title,
        description: description || null,
        raw_gemini_response: rawGeminiResponse || null,
        status: 'active'
      })
      .select()
      .single();

    if (sopError) {
      console.error('Error creating SOP:', sopError);
      return res.status(500).json({ error: 'Failed to create SOP' });
    }

    // Insert SOP steps
    const stepRecords = steps.map(step => ({
      sop_id: sop.id,
      step_order: step.stepOrder,
      time_label: step.timeLabel,
      task_title: step.taskTitle,
      task_description: step.taskDescription
    }));

    const { data: insertedSteps, error: stepsError } = await supabase
      .from('sop_steps')
      .insert(stepRecords)
      .select();

    if (stepsError) {
      console.error('Error creating SOP steps:', stepsError);
      return res.status(500).json({ error: 'Failed to create SOP steps' });
    }

    res.json({
      sop: {
        ...sop,
        steps: insertedSteps
      }
    });
  } catch (error) {
    console.error('Error in POST /sops:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get SOPs for a user
router.get('/sops/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const { data: sops, error } = await supabase
      .from('sops')
      .select(`
        *,
        patients (
          id,
          name,
          age,
          disease_condition
        ),
        sop_steps (
          id,
          step_order,
          time_label,
          task_title,
          task_description,
          is_completed
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching SOPs:', error);
      return res.status(500).json({ error: 'Failed to fetch SOPs' });
    }

    res.json({ sops });
  } catch (error) {
    console.error('Error in GET /sops/user/:userId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get single SOP with details
router.get('/sops/:sopId', async (req, res) => {
  try {
    const { sopId } = req.params;

    const { data: sop, error } = await supabase
      .from('sops')
      .select(`
        *,
        patients (
          id,
          name,
          age,
          disease_condition,
          patient_medicines (
            id,
            medicine_name,
            photo_url
          )
        ),
        sop_steps (
          id,
          step_order,
          time_label,
          task_title,
          task_description,
          is_completed,
          completed_at
        )
      `)
      .eq('id', sopId)
      .single();

    if (error) {
      console.error('Error fetching SOP:', error);
      return res.status(404).json({ error: 'SOP not found' });
    }

    res.json({ sop });
  } catch (error) {
    console.error('Error in GET /sops/:sopId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update SOP step
router.patch('/sops/steps/:stepId', async (req, res) => {
  try {
    const { stepId } = req.params;
    const { timeLabel, taskTitle, taskDescription } = req.body;

    const updateData = {};
    if (timeLabel !== undefined) updateData.time_label = timeLabel;
    if (taskTitle !== undefined) updateData.task_title = taskTitle;
    if (taskDescription !== undefined) updateData.task_description = taskDescription;

    const { data: step, error } = await supabase
      .from('sop_steps')
      .update(updateData)
      .eq('id', stepId)
      .select()
      .single();

    if (error) {
      console.error('Error updating SOP step:', error);
      return res.status(500).json({ error: 'Failed to update SOP step' });
    }

    res.json({ step });
  } catch (error) {
    console.error('Error in PATCH /sops/steps/:stepId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete SOP step
router.delete('/sops/steps/:stepId', async (req, res) => {
  try {
    const { stepId } = req.params;

    const { error } = await supabase
      .from('sop_steps')
      .delete()
      .eq('id', stepId);

    if (error) {
      console.error('Error deleting SOP step:', error);
      return res.status(500).json({ error: 'Failed to delete SOP step' });
    }

    res.json({ message: 'SOP step deleted successfully' });
  } catch (error) {
    console.error('Error in DELETE /sops/steps/:stepId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mark SOP step as completed
router.patch('/sops/steps/:stepId/complete', async (req, res) => {
  try {
    const { stepId } = req.params;
    const { isCompleted } = req.body;

    const { data: step, error } = await supabase
      .from('sop_steps')
      .update({
        is_completed: isCompleted,
        completed_at: isCompleted ? new Date().toISOString() : null
      })
      .eq('id', stepId)
      .select()
      .single();

    if (error) {
      console.error('Error updating step completion:', error);
      return res.status(500).json({ error: 'Failed to update step completion' });
    }

    res.json({ step });
  } catch (error) {
    console.error('Error in PATCH /sops/steps/:stepId/complete:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
