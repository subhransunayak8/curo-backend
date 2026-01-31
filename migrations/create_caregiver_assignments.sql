-- Create caregiver-patient assignments table
-- This allows caregivers to be assigned to specific patients

CREATE TABLE IF NOT EXISTS caregiver_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caregiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    notes TEXT,
    UNIQUE(caregiver_id, patient_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_caregiver_assignments_caregiver 
    ON caregiver_assignments(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_assignments_patient 
    ON caregiver_assignments(patient_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_assignments_status 
    ON caregiver_assignments(status);

-- Add RLS policies
ALTER TABLE caregiver_assignments ENABLE ROW LEVEL SECURITY;

-- Caregivers can view their own assignments
CREATE POLICY "Caregivers can view their assignments"
    ON caregiver_assignments FOR SELECT
    USING (caregiver_id = auth.uid());

-- Users can view assignments for their patients
CREATE POLICY "Users can view assignments for their patients"
    ON caregiver_assignments FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Users can create assignments for their patients
CREATE POLICY "Users can create assignments for their patients"
    ON caregiver_assignments FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Users can update assignments for their patients
CREATE POLICY "Users can update assignments for their patients"
    ON caregiver_assignments FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Users can delete assignments for their patients
CREATE POLICY "Users can delete assignments for their patients"
    ON caregiver_assignments FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

COMMENT ON TABLE caregiver_assignments IS 'Links caregivers to patients they are responsible for';
COMMENT ON COLUMN caregiver_assignments.caregiver_id IS 'User ID of the caregiver (role=caregiver)';
COMMENT ON COLUMN caregiver_assignments.patient_id IS 'Patient ID being assigned';
COMMENT ON COLUMN caregiver_assignments.assigned_by IS 'User ID who created the assignment (usually the patient owner)';
COMMENT ON COLUMN caregiver_assignments.status IS 'active or inactive';
