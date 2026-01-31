-- ============================================================================
-- FINAL SOP SYSTEM SETUP - NO VERIFICATION QUERIES
-- This will create the tables without any checks that could fail
-- ============================================================================

-- Step 1: Create update function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create caregivers table
CREATE TABLE IF NOT EXISTS caregivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create patients table
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    age INTEGER,
    disease_condition TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create patient_medicines table
CREATE TABLE IF NOT EXISTS patient_medicines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    medicine_name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Create sops table
CREATE TABLE IF NOT EXISTS sops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    caregiver_id UUID REFERENCES caregivers(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    raw_gemini_response JSONB,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 6: Create sop_steps table
CREATE TABLE IF NOT EXISTS sop_steps (
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

-- Step 7: Create indexes
CREATE INDEX IF NOT EXISTS idx_caregivers_user ON caregivers(user_id);
CREATE INDEX IF NOT EXISTS idx_patients_user ON patients(user_id);
CREATE INDEX IF NOT EXISTS idx_patient_medicines_patient ON patient_medicines(patient_id);
CREATE INDEX IF NOT EXISTS idx_sops_user ON sops(user_id);
CREATE INDEX IF NOT EXISTS idx_sops_patient ON sops(patient_id);
CREATE INDEX IF NOT EXISTS idx_sops_caregiver ON sops(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_sop ON sop_steps(sop_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_order ON sop_steps(sop_id, step_order);

-- Step 8: Add triggers
DROP TRIGGER IF EXISTS update_caregivers_updated_at ON caregivers;
CREATE TRIGGER update_caregivers_updated_at 
    BEFORE UPDATE ON caregivers
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

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
COMMENT ON TABLE caregivers IS 'Caregivers who can be assigned to SOPs';
COMMENT ON TABLE patients IS 'Patient information for SOP creation';
COMMENT ON TABLE patient_medicines IS 'Medicines associated with patients';
COMMENT ON TABLE sops IS 'Standard Operating Procedures (Care Plans)';
COMMENT ON TABLE sop_steps IS 'Individual tasks/steps in an SOP with timestamps';

-- Done! Tables created successfully
