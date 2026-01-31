-- Add rejection tracking fields to sop_steps table

-- Add validation_status column (pending, approved, rejected)
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS validation_status VARCHAR(20) DEFAULT 'pending';

-- Add validation_message column for rejection reason
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS validation_message TEXT;

-- Add rejection_timestamp column
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE;

-- Add rejection_count column to track multiple rejections
ALTER TABLE sop_steps 
ADD COLUMN IF NOT EXISTS rejection_count INTEGER DEFAULT 0;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_sop_steps_validation_status 
ON sop_steps(validation_status);

-- Update existing completed steps to 'approved' status
UPDATE sop_steps 
SET validation_status = 'approved' 
WHERE is_completed = true AND validation_status = 'pending';

-- Add comment for documentation
COMMENT ON COLUMN sop_steps.validation_status IS 'Status of task validation: pending, approved, rejected';
COMMENT ON COLUMN sop_steps.validation_message IS 'Reason for rejection or validation notes';
COMMENT ON COLUMN sop_steps.rejected_at IS 'Timestamp when task was rejected';
COMMENT ON COLUMN sop_steps.rejection_count IS 'Number of times task has been rejected';
