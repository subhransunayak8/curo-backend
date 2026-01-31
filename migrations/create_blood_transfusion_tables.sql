-- Blood Transfusion Monitoring System
-- Phase 2: Database Persistence

-- Create blood_transfusions table
CREATE TABLE IF NOT EXISTS blood_transfusions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id VARCHAR(255) NOT NULL,
    patient_id UUID NOT NULL,
    caregiver_id UUID NOT NULL,
    
    -- Blood pouch details
    pouch_volume_ml INTEGER NOT NULL CHECK (pouch_volume_ml >= 100 AND pouch_volume_ml <= 1000),
    drop_factor VARCHAR(20) NOT NULL CHECK (drop_factor IN ('STANDARD', 'MICRO_DRIP')),
    drop_rate_per_minute INTEGER NOT NULL CHECK (drop_rate_per_minute >= 20 AND drop_rate_per_minute <= 100),
    
    -- Timing
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    expected_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    alert_threshold_minutes INTEGER NOT NULL DEFAULT 15,
    
    -- Status
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'IN_PROGRESS', 'PAUSED', 'COMPLETED', 'STOPPED_EARLY')),
    paused_at TIMESTAMP WITH TIME ZONE,
    pause_duration_ms BIGINT DEFAULT 0,
    
    -- Notes and complications
    notes TEXT,
    complications TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Foreign keys
    FOREIGN KEY (caregiver_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create blood_transfusion_progress table (for tracking progress snapshots)
CREATE TABLE IF NOT EXISTS blood_transfusion_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfusion_id UUID NOT NULL,
    
    -- Progress data
    elapsed_time_ms BIGINT NOT NULL,
    remaining_time_ms BIGINT NOT NULL,
    drops_administered INTEGER NOT NULL,
    volume_administered_ml DECIMAL(10, 2) NOT NULL,
    progress_percentage DECIMAL(5, 2) NOT NULL,
    
    -- Timestamp
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Foreign key
    FOREIGN KEY (transfusion_id) REFERENCES blood_transfusions(id) ON DELETE CASCADE
);

-- Create blood_transfusion_notes table (for timestamped notes)
CREATE TABLE IF NOT EXISTS blood_transfusion_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfusion_id UUID NOT NULL,
    
    -- Note content
    note TEXT NOT NULL,
    note_type VARCHAR(20) DEFAULT 'GENERAL' CHECK (note_type IN ('GENERAL', 'COMPLICATION', 'OBSERVATION')),
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Foreign key
    FOREIGN KEY (transfusion_id) REFERENCES blood_transfusions(id) ON DELETE CASCADE
);

-- Create blood_transfusion_alerts table (for tracking alert history)
CREATE TABLE IF NOT EXISTS blood_transfusion_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfusion_id UUID NOT NULL,
    
    -- Alert details
    alert_type VARCHAR(20) NOT NULL CHECK (alert_type IN ('THRESHOLD', 'FIVE_MINUTES', 'COMPLETION')),
    alert_message TEXT NOT NULL,
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    
    -- Foreign key
    FOREIGN KEY (transfusion_id) REFERENCES blood_transfusions(id) ON DELETE CASCADE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_blood_transfusions_caregiver ON blood_transfusions(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_blood_transfusions_patient ON blood_transfusions(patient_id);
CREATE INDEX IF NOT EXISTS idx_blood_transfusions_status ON blood_transfusions(status);
CREATE INDEX IF NOT EXISTS idx_blood_transfusions_start_time ON blood_transfusions(start_time);
CREATE INDEX IF NOT EXISTS idx_blood_transfusion_progress_transfusion ON blood_transfusion_progress(transfusion_id);
CREATE INDEX IF NOT EXISTS idx_blood_transfusion_notes_transfusion ON blood_transfusion_notes(transfusion_id);
CREATE INDEX IF NOT EXISTS idx_blood_transfusion_alerts_transfusion ON blood_transfusion_alerts(transfusion_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_blood_transfusion_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS blood_transfusions_updated_at ON blood_transfusions;
CREATE TRIGGER blood_transfusions_updated_at
    BEFORE UPDATE ON blood_transfusions
    FOR EACH ROW
    EXECUTE FUNCTION update_blood_transfusion_updated_at();

-- Grant permissions (adjust based on your RLS policies)
ALTER TABLE blood_transfusions ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_transfusion_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_transfusion_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE blood_transfusion_alerts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for blood_transfusions
CREATE POLICY "Caregivers can view their own transfusions"
    ON blood_transfusions FOR SELECT
    USING (caregiver_id = auth.uid());

CREATE POLICY "Caregivers can insert their own transfusions"
    ON blood_transfusions FOR INSERT
    WITH CHECK (caregiver_id = auth.uid());

CREATE POLICY "Caregivers can update their own transfusions"
    ON blood_transfusions FOR UPDATE
    USING (caregiver_id = auth.uid());

-- RLS Policies for blood_transfusion_progress
CREATE POLICY "Caregivers can view progress of their transfusions"
    ON blood_transfusion_progress FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM blood_transfusions
        WHERE blood_transfusions.id = blood_transfusion_progress.transfusion_id
        AND blood_transfusions.caregiver_id = auth.uid()
    ));

CREATE POLICY "Caregivers can insert progress for their transfusions"
    ON blood_transfusion_progress FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM blood_transfusions
        WHERE blood_transfusions.id = blood_transfusion_progress.transfusion_id
        AND blood_transfusions.caregiver_id = auth.uid()
    ));

-- RLS Policies for blood_transfusion_notes
CREATE POLICY "Caregivers can view notes of their transfusions"
    ON blood_transfusion_notes FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM blood_transfusions
        WHERE blood_transfusions.id = blood_transfusion_notes.transfusion_id
        AND blood_transfusions.caregiver_id = auth.uid()
    ));

CREATE POLICY "Caregivers can insert notes for their transfusions"
    ON blood_transfusion_notes FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM blood_transfusions
        WHERE blood_transfusions.id = blood_transfusion_notes.transfusion_id
        AND blood_transfusions.caregiver_id = auth.uid()
    ));

-- RLS Policies for blood_transfusion_alerts
CREATE POLICY "Caregivers can view alerts of their transfusions"
    ON blood_transfusion_alerts FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM blood_transfusions
        WHERE blood_transfusions.id = blood_transfusion_alerts.transfusion_id
        AND blood_transfusions.caregiver_id = auth.uid()
    ));

CREATE POLICY "Caregivers can insert alerts for their transfusions"
    ON blood_transfusion_alerts FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM blood_transfusions
        WHERE blood_transfusions.id = blood_transfusion_alerts.transfusion_id
        AND blood_transfusions.caregiver_id = auth.uid()
    ));

CREATE POLICY "Caregivers can update alerts for their transfusions"
    ON blood_transfusion_alerts FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM blood_transfusions
        WHERE blood_transfusions.id = blood_transfusion_alerts.transfusion_id
        AND blood_transfusions.caregiver_id = auth.uid()
    ));

-- Create view for transfusion summary
CREATE OR REPLACE VIEW blood_transfusion_summary AS
SELECT 
    bt.id,
    bt.task_id,
    bt.patient_id,
    bt.caregiver_id,
    bt.pouch_volume_ml,
    bt.drop_factor,
    bt.drop_rate_per_minute,
    bt.start_time,
    bt.expected_end_time,
    bt.actual_end_time,
    bt.status,
    bt.notes,
    bt.complications,
    bt.created_at,
    bt.updated_at,
    -- Calculate duration
    CASE 
        WHEN bt.actual_end_time IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (bt.actual_end_time - bt.start_time)) / 60
        ELSE 
            EXTRACT(EPOCH FROM (bt.expected_end_time - bt.start_time)) / 60
    END AS duration_minutes,
    -- Count notes
    (SELECT COUNT(*) FROM blood_transfusion_notes WHERE transfusion_id = bt.id) AS note_count,
    -- Count alerts
    (SELECT COUNT(*) FROM blood_transfusion_alerts WHERE transfusion_id = bt.id) AS alert_count
FROM blood_transfusions bt;

-- Grant access to view
GRANT SELECT ON blood_transfusion_summary TO authenticated;

COMMENT ON TABLE blood_transfusions IS 'Stores blood transfusion monitoring records';
COMMENT ON TABLE blood_transfusion_progress IS 'Stores progress snapshots for transfusions';
COMMENT ON TABLE blood_transfusion_notes IS 'Stores timestamped notes for transfusions';
COMMENT ON TABLE blood_transfusion_alerts IS 'Stores alert history for transfusions';
COMMENT ON VIEW blood_transfusion_summary IS 'Summary view of blood transfusions with calculated fields';
