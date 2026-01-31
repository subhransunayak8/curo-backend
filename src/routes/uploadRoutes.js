const express = require('express');
const router = express.Router();
const multer = require('multer');
const { createClient } = require('@supabase/supabase-js');
const { v4: uuidv4 } = require('uuid');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept images only
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Only image files are allowed'), false);
    }
    cb(null, true);
  }
});

// Upload medicine photo
router.post('/medicine-photo', upload.single('photo'), async (req, res) => {
  try {
    const { userId, patientId } = req.body;

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    // Generate unique filename
    const fileExt = req.file.originalname.split('.').pop();
    const fileName = `${userId}/${uuidv4()}.${fileExt}`;

    // Upload to Supabase Storage
    const { data, error } = await supabase.storage
      .from('medicine-photos')
      .upload(fileName, req.file.buffer, {
        contentType: req.file.mimetype,
        upsert: false
      });

    if (error) {
      console.error('Error uploading to Supabase Storage:', error);
      return res.status(500).json({ error: 'Failed to upload photo' });
    }

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('medicine-photos')
      .getPublicUrl(fileName);

    res.json({
      success: true,
      photoUrl: publicUrl,
      fileName: fileName
    });
  } catch (error) {
    console.error('Error in POST /upload/medicine-photo:', error);
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
});

// Delete medicine photo
router.delete('/medicine-photo', async (req, res) => {
  try {
    const { fileName } = req.body;

    if (!fileName) {
      return res.status(400).json({ error: 'fileName is required' });
    }

    const { error } = await supabase.storage
      .from('medicine-photos')
      .remove([fileName]);

    if (error) {
      console.error('Error deleting from Supabase Storage:', error);
      return res.status(500).json({ error: 'Failed to delete photo' });
    }

    res.json({ success: true, message: 'Photo deleted successfully' });
  } catch (error) {
    console.error('Error in DELETE /upload/medicine-photo:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
