-- Create comprehensive SOP system tables

-- Patients table
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    age INTEGER,
    disease_condition TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patient medicines table
CREATE TABLE IF NOT EXISTS patient_medicines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    medicine_name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SOPs table (updated structure)
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

-- SOP steps/tasks table
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_patients_user ON patients(user_id);
CREATE INDEX IF NOT EXISTS idx_patient_medicines_patient ON patient_medicines(patient_id);
CREATE INDEX IF NOT EXISTS idx_sops_user ON sops(user_id);
CREATE INDEX IF NOT EXISTS idx_sops_patient ON sops(patient_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_sop ON sop_steps(sop_id);
CREATE INDEX IF NOT EXISTS idx_sop_steps_order ON sop_steps(sop_id, step_order);

-- Add triggers for updated_at
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sops_updated_at BEFORE UPDATE ON sops
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sop_steps_updated_at BEFORE UPDATE ON sop_steps
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE sop_steps ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage own patients" ON patients FOR ALL USING (true);
CREATE POLICY "Users can manage patient medicines" ON patient_medicines FOR ALL USING (true);
CREATE POLICY "Users can manage SOP steps" ON sop_steps FOR ALL USING (true);

-- Comments
COMMENT ON TABLE patients IS 'Patient information for SOP creation';
COMMENT ON TABLE patient_medicines IS 'Medicines associated with patients';
COMMENT ON TABLE sop_steps IS 'Individual tasks/steps in an SOP with timestamps';
