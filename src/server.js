const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const config = require('./config/config');

// Import routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const prescriptionRoutes = require('./routes/prescriptionRoutes');

const app = express();

// Middleware
app.use(cors({
  origin: config.cors.allowedOrigins === '*' ? '*' : config.cors.allowedOrigins.split(',')
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Health check
app.get('/', (req, res) => {
  res.json({
    message: 'CURA Backend API',
    version: '1.0.0',
    status: 'healthy'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/prescriptions', prescriptionRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const PORT = config.port;
app.listen(PORT, () => {
  console.log(`🚀 CURA Backend running on port ${PORT}`);
  console.log(`📝 Environment: ${config.nodeEnv}`);
  console.log(`🔗 API: http://localhost:${PORT}`);
});

module.exports = app;
