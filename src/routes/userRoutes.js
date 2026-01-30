const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { supabase } = require('../config/supabase');

const router = express.Router();

// Get user profile
router.get('/profile',
  query('user_id').notEmpty().withMessage('User ID is required'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { user_id } = req.query;

      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', user_id)
        .single();

      if (error || !data) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json(data);
    } catch (error) {
      console.error('Error getting profile:', error);
      res.status(500).json({ error: 'Failed to get profile' });
    }
  }
);

// Update user profile
router.put('/profile',
  query('user_id').notEmpty().withMessage('User ID is required'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { user_id } = req.query;
      const updateData = req.body;

      // Remove undefined values
      Object.keys(updateData).forEach(key => 
        updateData[key] === undefined && delete updateData[key]
      );

      const { data, error } = await supabase
        .from('users')
        .update(updateData)
        .eq('id', user_id)
        .select()
        .single();

      if (error || !data) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json(data);
    } catch (error) {
      console.error('Error updating profile:', error);
      res.status(500).json({ error: 'Failed to update profile' });
    }
  }
);

// Complete registration
router.post('/complete-registration',
  query('user_id').notEmpty().withMessage('User ID is required'),
  body('phone').notEmpty().withMessage('Phone is required'),
  body('full_name').notEmpty().withMessage('Full name is required'),
  body('age').isInt({ min: 1 }).withMessage('Valid age is required'),
  body('gender').notEmpty().withMessage('Gender is required'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { user_id } = req.query;
      const { phone, full_name, email, age, gender, address } = req.body;

      const updateData = {
        phone,
        full_name,
        age,
        gender
      };

      if (email) updateData.email = email;
      if (address) updateData.address = address;

      const { data, error } = await supabase
        .from('users')
        .update(updateData)
        .eq('id', user_id)
        .select()
        .single();

      if (error || !data) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json(data);
    } catch (error) {
      console.error('Error completing registration:', error);
      res.status(500).json({ error: 'Failed to complete registration' });
    }
  }
);

module.exports = router;
