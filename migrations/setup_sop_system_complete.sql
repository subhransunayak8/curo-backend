-- ============================================================================
-- COMPLETE SOP SYSTEM DATABASE SETUP
-- Run this script in your Supabase SQL Editor
-- ============================================================================

-- Step 1: Create update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create caregivers table if it doesn't exist (referenced by sops table)
CREATE TABLE IF NOT EXISTS caregivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create patients table
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    age INTEGER,
    disease_condition TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create patient_medicines table
CREATE TABLE IF NOT EXISTS patient_medicines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    medicine_name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Create sops table
CREATE TABLE IF NOT EXISTS sops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
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
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sop_id UUID REFERENCES sops(id) ON DELETE CASCADE,
    step_order INTEGER NOT NULL,
    time_label VARCHAR(100),
    task_title VARCHAR(255) NOT NULL,
    task_description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 7: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_caregivers_user ON caregivers(user_id);
CREATE INDEX IF NOT EXISTS idx_patients_user ON patients(user_id);
CREATE INDEX IF NOT EXISTS idx_patient_medicines_patient ON patient_medicines(patient_id);
CREATE INDEX IF NOT EXISTS idx_sops_user ON sops(user_id);
CREATE INDEX IF NOT EXISTS idx_sops_patient ON sops(patient_id);
CREATE INDEX IF NOT EXISTS idx_sops_caregiver ON sops(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_sop ON sop_steps(sop_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_order ON sop_steps(sop_id, step_order);

-- Step 8: Add triggers for updated_at columns
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

-- Step 9: Enable Row Level Security (RLS)
ALTER TABLE caregivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE sops ENABLE ROW LEVEL SECURITY;
ALTER TABLE sop_steps ENABLE ROW LEVEL SECURITY;

-- Step 10: Create RLS Policies
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage own caregivers" ON caregivers;
DROP POLICY IF EXISTS "Users can manage own patients" ON patients;
DROP POLICY IF EXISTS "Users can manage patient medicines" ON patient_medicines;
DROP POLICY IF EXISTS "Users can manage own sops" ON sops;
DROP POLICY IF EXISTS "Users can manage SOP steps" ON sop_steps;

-- Caregivers policies
CREATE POLICY "Users can manage own caregivers" 
    ON caregivers 
    FOR ALL 
    USING (auth.uid() = user_id);

-- Patients policies
CREATE POLICY "Users can manage own patients" 
    ON patients 
    FOR ALL 
    USING (auth.uid() = user_id);

-- Patient medicines policies (access through patient)
CREATE POLICY "Users can manage patient medicines" 
    ON patient_medicines 
    FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM patients 
            WHERE patients.id = patient_medicines.patient_id 
            AND patients.user_id = auth.uid()
        )
    );

-- SOPs policies
CREATE POLICY "Users can manage own sops" 
    ON sops 
    FOR ALL 
    USING (auth.uid() = user_id);

-- SOP steps policies (access through sop)
CREATE POLICY "Users can manage SOP steps" 
    ON sop_steps 
    FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM sops 
            WHERE sops.id = sop_steps.sop_id 
            AND sops.user_id = auth.uid()
        )
    );

-- Step 11: Add helpful comments
COMMENT ON TABLE caregivers IS 'Caregivers who can be assigned to SOPs';
COMMENT ON TABLE patients IS 'Patient information for SOP creation';
COMMENT ON TABLE patient_medicines IS 'Medicines associated with patients';
COMMENT ON TABLE sops IS 'Standard Operating Procedures (Care Plans)';
COMMENT ON TABLE sop_steps IS 'Individual tasks/steps in an SOP with timestamps';

COMMENT ON COLUMN sops.raw_gemini_response IS 'Raw JSON response from Gemini AI for reference';
COMMENT ON COLUMN sops.status IS 'Status: active, completed, archived';
COMMENT ON COLUMN sop_steps.time_label IS 'Time label like "08:00 AM" or "Morning"';
COMMENT ON COLUMN sop_steps.step_order IS 'Order of execution (1, 2, 3, ...)';
COMMENT ON COLUMN sop_steps.is_completed IS 'Whether this step has been completed';

-- ============================================================================
-- VERIFICATION QUERIES
-- Run these to verify the setup
-- ============================================================================

-- Check if all tables exist
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
AND table_name IN ('caregivers', 'patients', 'patient_medicines', 'sops', 'sop_steps')
ORDER BY table_name;

-- Check if all indexes exist
SELECT 
    indexname,
    tablename
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('caregivers', 'patients', 'patient_medicines', 'sops', 'sop_steps')
ORDER BY tablename, indexname;

-- Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('caregivers', 'patients', 'patient_medicines', 'sops', 'sop_steps')
ORDER BY tablename;

-- ============================================================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Uncomment below to insert sample data for testing

/*
-- Insert a sample patient (replace 'your-user-id' with actual user UUID)
INSERT INTO patients (user_id, name, age, disease_condition)
VALUES ('your-user-id', 'John Doe', 65, 'Diabetes Type 2')
RETURNING id;

-- Insert sample medicines (replace 'patient-id' with the ID from above)
INSERT INTO patient_medicines (patient_id, medicine_name)
VALUES 
    ('patient-id', 'Metformin 500mg'),
    ('patient-id', 'Aspirin 75mg');

-- Insert a sample SOP (replace IDs)
INSERT INTO sops (user_id, patient_id, title, description, status)
VALUES ('your-user-id', 'patient-id', 'Daily Care Plan for John Doe', 'Comprehensive diabetes management plan', 'active')
RETURNING id;

-- Insert sample SOP steps (replace 'sop-id')
INSERT INTO sop_steps (sop_id, step_order, time_label, task_title, task_description)
VALUES 
    ('sop-id', 1, '08:00 AM', 'Morning Medication', 'Administer Metformin 500mg with water before breakfast'),
    ('sop-id', 2, '08:30 AM', 'Breakfast', 'Provide balanced breakfast with low sugar content'),
    ('sop-id', 3, '09:00 AM', 'Blood Sugar Check', 'Measure and record blood glucose level');
*/

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

SELECT 'SOP System Database Setup Complete!' as status;
