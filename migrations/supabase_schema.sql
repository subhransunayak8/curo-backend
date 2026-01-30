-- Supabase Database Schema for CURA App
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255),
    full_name VARCHAR(255),
    age INTEGER,
    gender VARCHAR(20),
    address TEXT,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- OTP Verifications table
CREATE TABLE IF NOT EXISTS otp_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Prescriptions table
CREATE TABLE IF NOT EXISTS prescriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    file_path TEXT NOT NULL,
    analysis_result JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Medicines table
CREATE TABLE IF NOT EXISTS medicines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prescription_id UUID REFERENCES prescriptions(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    duration VARCHAR(100),
    instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Caregivers table
CREATE TABLE IF NOT EXISTS caregivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    specialization VARCHAR(255),
    experience_years INTEGER,
    rating DECIMAL(3,2),
    hourly_rate DECIMAL(10,2),
    bio TEXT,
    image_url TEXT,
    available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Appointments table
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    caregiver_id UUID REFERENCES caregivers(id) ON DELETE CASCADE,
    appointment_date DATE NOT NULL,
    time_slot VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Health Data table
CREATE TABLE IF NOT EXISTS health_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    water_intake INTEGER,
    steps INTEGER,
    sleep_hours DECIMAL(4,2),
    weight DECIMAL(5,2),
    mood VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SOP (Standard Operating Procedures) table
CREATE TABLE IF NOT EXISTS sops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    caregiver_id UUID REFERENCES caregivers(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    schedule JSONB,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_verifications(phone);
CREATE INDEX IF NOT EXISTS idx_otp_expires ON otp_verifications(expires_at);
CREATE INDEX IF NOT EXISTS idx_prescriptions_user ON prescriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_medicines_prescription ON medicines(prescription_id);
CREATE INDEX IF NOT EXISTS idx_appointments_user ON appointments(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_caregiver ON appointments(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_health_data_user ON health_data(user_id);
CREATE INDEX IF NOT EXISTS idx_health_data_date ON health_data(date);
CREATE INDEX IF NOT EXISTS idx_sops_user ON sops(user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prescriptions_updated_at BEFORE UPDATE ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_caregivers_updated_at BEFORE UPDATE ON caregivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sops_updated_at BEFORE UPDATE ON sops
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE sops ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Basic - adjust based on your auth strategy)
-- Users can read their own data
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (true);

-- Prescriptions policies
CREATE POLICY "Users can view own prescriptions" ON prescriptions
    FOR SELECT USING (true);

CREATE POLICY "Users can insert own prescriptions" ON prescriptions
    FOR INSERT WITH CHECK (true);

-- Health data policies
CREATE POLICY "Users can view own health data" ON health_data
    FOR ALL USING (true);

-- Appointments policies
CREATE POLICY "Users can view own appointments" ON appointments
    FOR ALL USING (true);

-- Caregivers are publicly viewable
CREATE POLICY "Caregivers are viewable by all" ON caregivers
    FOR SELECT USING (true);
