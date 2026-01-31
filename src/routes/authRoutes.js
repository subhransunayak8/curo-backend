const express = require('express');
const { body, validationResult } = require('express-validator');
const authService = require('../services/authService');

const router = express.Router();

// Register new user
router.post('/register',
  body('email').isEmail().withMessage('Invalid email format'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('name').optional().trim(),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, name } = req.body;
      const result = await authService.register(email, password, name);
      res.json(result);
    } catch (error) {
      console.error('Error in register:', error);
      if (error.message === 'User with this email already exists') {
        return res.status(409).json({ error: error.message });
      }
      res.status(500).json({ error: 'Failed to register user' });
    }
  }
);

// Login user
router.post('/login',
  body('email').isEmail().withMessage('Invalid email format'),
  body('password').notEmpty().withMessage('Password is required'),
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password } = req.body;
      const result = await authService.login(email, password);
      res.json(result);
    } catch (error) {
      console.error('Error in login:', error);
      if (error.message === 'Invalid email or password') {
        return res.status(401).json({ error: error.message });
      }
      res.status(500).json({ error: 'Failed to login' });
    }
  }
);

// Logout
router.post('/logout', (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

module.exports = router;
