const express = require('express');
const { body, validationResult } = require('express-validator');
const geminiService = require('../services/geminiService');
const { supabase } = require('../config/supabase');

const router = express.Router();

// Analyze prescription
router.post('/analyze',
  body('medicine_text').notEmpty().withMessage('Medicine text is required'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { medicine_text } = req.body;
      const user_id = req.headers['x-user-id'];

      // Analyze with Gemini
      const analysisData = await geminiService.analyzePrescription(medicine_text);

      let prescriptionId = null;

      // Save to database if user_id provided
      if (user_id) {
        try {
          const { data, error } = await supabase
            .from('prescriptions')
            .insert({
              user_id,
              medicine_text,
              analysis: analysisData,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
              status: 'active'
            })
            .select()
            .single();

          if (!error && data) {
            prescriptionId = data.id;
          }
        } catch (saveError) {
          console.warn('Failed to save prescription:', saveError);
        }
      }

      res.json({
        success: true,
        data: analysisData,
        message: 'Prescription analyzed successfully',
        prescription_id: prescriptionId
      });
    } catch (error) {
      console.error('Error analyzing prescription:', error);
      res.status(500).json({ error: 'Failed to analyze prescription' });
    }
  }
);

// Get user prescriptions
router.get('/user/:user_id', async (req, res) => {
  try {
    const { user_id } = req.params;
    const limit = parseInt(req.query.limit) || 10;

    const { data, error } = await supabase
      .from('prescriptions')
      .select('*')
      .eq('user_id', user_id)
      .eq('status', 'active')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    res.json({
      success: true,
      data: data || [],
      count: data ? data.length : 0
    });
  } catch (error) {
    console.error('Error getting prescriptions:', error);
    res.status(500).json({ error: 'Failed to get prescriptions' });
  }
});

// Get prescription by ID
router.get('/:prescription_id', async (req, res) => {
  try {
    const { prescription_id } = req.params;

    const { data, error } = await supabase
      .from('prescriptions')
      .select('*')
      .eq('id', prescription_id)
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Prescription not found' });
    }

    res.json({
      success: true,
      data
    });
  } catch (error) {
    console.error('Error getting prescription:', error);
    res.status(500).json({ error: 'Failed to get prescription' });
  }
});

module.exports = router;
