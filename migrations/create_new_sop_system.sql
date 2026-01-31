-- ============================================================================
-- CREATE NEW SOP SYSTEM - Works with your existing database
-- This backs up old sops table and creates new structure
-- ============================================================================

-- Step 1: Backup old sops table (rename it)
ALTER TABLE IF EXISTS sops RENAME TO sops_old_backup;

-- Step 2: Create update function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create patients table (NEW)
CREATE TABLE patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    age INTEGER,
    disease_condition TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create patient_medicines table (NEW)
CREATE TABLE patient_medicines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    medicine_name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Create NEW sops table with proper structure
CREATE TABLE sops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    caregiver_id UUID REFERENCES caregivers(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    raw_gemini_response JSONB,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 6: Create sop_steps table (NEW)
CREATE TABLE sop_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sop_id UUID NOT NULL REFERENCES sops(id) ON DELETE CASCADE,
    step_order INTEGER NOT NULL,
    time_label VARCHAR(100),
    task_title VARCHAR(255) NOT NULL,
    task_description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 7: Create indexes (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_patients_user ON patients(user_id);
CREATE INDEX IF NOT EXISTS idx_patient_medicines_patient ON patient_medicines(patient_id);
CREATE INDEX IF NOT EXISTS idx_sops_user ON sops(user_id);
CREATE INDEX IF NOT EXISTS idx_sops_patient ON sops(patient_id);
CREATE INDEX IF NOT EXISTS idx_sops_caregiver ON sops(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_sop ON sop_steps(sop_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_order ON sop_steps(sop_id, step_order);

-- Step 8: Add triggers (drop first if they exist)
DROP TRIGGER IF EXISTS update_patients_updated_at ON patients;
CREATE TRIGGER update_patients_updated_at 
    BEFORE UPDATE ON patients
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sops_updated_at ON sops;
CREATE TRIGGER update_sops_updated_at 
    BEFORE UPDATE ON sops
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sop_steps_updated_at ON sop_steps;
CREATE TRIGGER update_sop_steps_updated_at 
    BEFORE UPDATE ON sop_steps
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Step 9: Add comments
COMMENT ON TABLE patients IS 'Patient information for SOP creation';
COMMENT ON TABLE patient_medicines IS 'Medicines associated with patients';
COMMENT ON TABLE sops IS 'Standard Operating Procedures (Care Plans) - NEW STRUCTURE';
COMMENT ON TABLE sop_steps IS 'Individual tasks/steps in an SOP with timestamps';
COMMENT ON TABLE sops_old_backup IS 'Backup of old SOP structure';

-- Step 10: Success message
SELECT 
    'SUCCESS!' as status,
    'New SOP system created' as message,
    'Old sops table backed up as sops_old_backup' as note;
