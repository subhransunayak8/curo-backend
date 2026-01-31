-- ============================================================================
-- COMPLETE SOP SYSTEM DATABASE SETUP - FIXED VERSION
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

-- Step 2: Users table should already exist from auth setup
-- We'll just verify it exists and add name column if missing
DO $$
BEGIN
    -- Add name column to users table if it doesn't exist
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'name'
    ) THEN
        ALTER TABLE users ADD COLUMN name VARCHAR(255);
    END IF;
END $$;

-- Step 3: Create caregivers table
DROP TABLE IF EXISTS caregivers CASCADE;
CREATE TABLE caregivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create patients table
DROP TABLE IF EXISTS patients CASCADE;
CREATE TABLE patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    age INTEGER,
    disease_condition TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Create patient_medicines table
DROP TABLE IF EXISTS patient_medicines CASCADE;
CREATE TABLE patient_medicines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    medicine_name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 6: Create sops table
DROP TABLE IF EXISTS sops CASCADE;
CREATE TABLE sops (
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

-- Step 7: Create sop_steps table
DROP TABLE IF EXISTS sop_steps CASCADE;
CREATE TABLE sop_steps (
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

-- Step 8: Create indexes for performance
CREATE INDEX idx_caregivers_user ON caregivers(user_id);
CREATE INDEX idx_patients_user ON patients(user_id);
CREATE INDEX idx_patient_medicines_patient ON patient_medicines(patient_id);
CREATE INDEX idx_sops_user ON sops(user_id);
CREATE INDEX idx_sops_patient ON sops(patient_id);
CREATE INDEX idx_sops_caregiver ON sops(caregiver_id);
CREATE INDEX idx_sop_steps_sop ON sop_steps(sop_id);
CREATE INDEX idx_sop_steps_order ON sop_steps(sop_id, step_order);

-- Step 9: Add triggers for updated_at columns
CREATE TRIGGER update_caregivers_updated_at 
    BEFORE UPDATE ON caregivers
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_patients_updated_at 
    BEFORE UPDATE ON patients
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sops_updated_at 
    BEFORE UPDATE ON sops
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sop_steps_updated_at 
    BEFORE UPDATE ON sop_steps
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Step 10: Enable Row Level Security (RLS) - OPTIONAL
-- Uncomment these if you want RLS enabled
/*
ALTER TABLE caregivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE sops ENABLE ROW LEVEL SECURITY;
ALTER TABLE sop_steps ENABLE ROW LEVEL SECURITY;

-- Simple RLS policies that allow all operations for now
CREATE POLICY "Allow all for caregivers" ON caregivers FOR ALL USING (true);
CREATE POLICY "Allow all for patients" ON patients FOR ALL USING (true);
CREATE POLICY "Allow all for patient_medicines" ON patient_medicines FOR ALL USING (true);
CREATE POLICY "Allow all for sops" ON sops FOR ALL USING (true);
CREATE POLICY "Allow all for sop_steps" ON sop_steps FOR ALL USING (true);
*/

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
-- INSERT SAMPLE DATA FOR TESTING
-- ============================================================================

-- Insert a test user (or use existing user)
-- First, let's get an existing user ID or create one
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Try to get an existing user
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    -- If no users exist, insert a test user
    IF test_user_id IS NULL THEN
        INSERT INTO users (id, email)
        VALUES ('00000000-0000-0000-0000-000000000001', 'test@example.com')
        ON CONFLICT (email) DO NOTHING
        RETURNING id INTO test_user_id;
        
        -- Update the name if column exists
        UPDATE users SET name = 'Test User' WHERE id = test_user_id;
    END IF;
    
    -- Store the user ID for later use
    test_user_id := COALESCE(test_user_id, '00000000-0000-0000-0000-000000000001');
END $$;

-- Insert a test patient using the first available user
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get the first user ID
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    -- Insert test patient
    INSERT INTO patients (id, user_id, name, age, disease_condition)
    VALUES (
        '00000000-0000-0000-0000-000000000002',
        test_user_id,
        'John Doe',
        65,
        'Diabetes Type 2'
    )
    ON CONFLICT (id) DO NOTHING;
END $$;

-- Insert test medicines
INSERT INTO patient_medicines (patient_id, medicine_name)
VALUES 
    ('00000000-0000-0000-0000-000000000002', 'Metformin 500mg'),
    ('00000000-0000-0000-0000-000000000002', 'Aspirin 75mg')
ON CONFLICT DO NOTHING;

-- Insert a test SOP using the first available user
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get the first user ID
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    -- Insert test SOP
    INSERT INTO sops (id, user_id, patient_id, title, description, status)
    VALUES (
        '00000000-0000-0000-0000-000000000003',
        test_user_id,
        '00000000-0000-0000-0000-000000000002',
        'Daily Care Plan for John Doe',
        'Comprehensive diabetes management plan',
        'active'
    )
    ON CONFLICT (id) DO NOTHING;
END $$;

-- Insert test SOP steps
INSERT INTO sop_steps (sop_id, step_order, time_label, task_title, task_description)
VALUES 
    ('00000000-0000-0000-0000-000000000003', 1, '08:00 AM', 'Morning Medication', 'Administer Metformin 500mg with water before breakfast. Monitor for any side effects.'),
    ('00000000-0000-0000-0000-000000000003', 2, '08:30 AM', 'Breakfast', 'Provide balanced breakfast with low sugar content. Ensure adequate hydration.'),
    ('00000000-0000-0000-0000-000000000003', 3, '09:00 AM', 'Blood Sugar Check', 'Measure and record blood glucose level. Target range: 80-130 mg/dL before meals.'),
    ('00000000-0000-0000-0000-000000000003', 4, '12:00 PM', 'Lunch', 'Provide balanced lunch. Monitor portion sizes.'),
    ('00000000-0000-0000-0000-000000000003', 5, '02:00 PM', 'Afternoon Medication', 'Administer Aspirin 75mg with water after lunch.'),
    ('00000000-0000-0000-0000-000000000003', 6, '06:00 PM', 'Dinner', 'Provide balanced dinner. Avoid high-sugar foods.'),
    ('00000000-0000-0000-0000-000000000003', 7, '08:00 PM', 'Evening Medication', 'Administer evening dose of Metformin 500mg.'),
    ('00000000-0000-0000-0000-000000000003', 8, '10:00 PM', 'Bedtime Routine', 'Check blood sugar before bed. Ensure patient is comfortable.')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if all tables exist
SELECT 
    'Tables Created' as status,
    COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'caregivers', 'patients', 'patient_medicines', 'sops', 'sop_steps');

-- Check sample data
SELECT 'Sample Data' as status, 
    (SELECT COUNT(*) FROM patients) as patients,
    (SELECT COUNT(*) FROM patient_medicines) as medicines,
    (SELECT COUNT(*) FROM sops) as sops,
    (SELECT COUNT(*) FROM sop_steps) as steps;

-- View sample SOP
SELECT 
    p.name as patient_name,
    p.age,
    p.disease_condition,
    s.title as sop_title,
    COUNT(ss.id) as total_steps
FROM patients p
JOIN sops s ON s.patient_id = p.id
JOIN sop_steps ss ON ss.sop_id = s.id
GROUP BY p.name, p.age, p.disease_condition, s.title;

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

-- Show the test user ID
SELECT 
    'SOP System Database Setup Complete!' as status,
    'Sample data inserted for testing' as note,
    (SELECT id FROM users LIMIT 1) as test_user_id;
