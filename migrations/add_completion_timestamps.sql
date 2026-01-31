-- Add completion timestamp and verification fields to sop_steps table

-- Add columns for completion tracking
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS completed_by VARCHAR(255),
ADD COLUMN IF NOT EXISTS photo_path TEXT,
ADD COLUMN IF NOT EXISTS photo_latitude DECIMAL(10, 8),
ADD COLUMN IF NOT EXISTS photo_longitude DECIMAL(11, 8),
ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected'));

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_sop_steps_completed_at ON sop_steps(completed_at);
CREATE INDEX IF NOT EXISTS idx_sop_steps_verification_status ON sop_steps(verification_status);

-- Add comments
COMMENT ON COLUMN sop_steps.completed_at IS 'Timestamp when the task was completed';
COMMENT ON COLUMN sop_steps.completed_by IS 'User ID or name of person who completed the task';
COMMENT ON COLUMN sop_steps.photo_path IS 'Path to the verification photo';
COMMENT ON COLUMN sop_steps.photo_latitude IS 'GPS latitude where photo was taken';
COMMENT ON COLUMN sop_steps.photo_longitude IS 'GPS longitude where photo was taken';
COMMENT ON COLUMN sop_steps.verification_status IS 'Status of task verification: pending, approved, rejected';

-- Update existing completed steps to have approved status
UPDATE sop_steps 
SET verification_status = 'approved' 
WHERE is_completed = true AND verification_status = 'pending';
