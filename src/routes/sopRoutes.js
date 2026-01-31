const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const supabase = createClient(
  process.env.SUPABASE_URL, 
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Generate SOP using Gemini AI
router.post('/generate', async (req, res) => {
  try {
    const { patientName, age, diseaseCondition, medicines } = req.body;

    // Validate input
    if (!patientName || !age || !diseaseCondition || !medicines || medicines.length === 0) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    console.log('=== GENERATING SOP ===');
    console.log('Patient:', patientName, 'Age:', age);
    console.log('Condition:', diseaseCondition);
    console.log('Medicines:', medicines.join(', '));

    const prompt = `
You are a medical care planning assistant. Based on the following patient information, create a detailed Standard Operating Procedure (SOP) for caregivers.

Patient Information:
- Name: ${patientName}
- Age: ${age}
- Disease/Condition: ${diseaseCondition}
- Medicines: ${medicines.join(', ')}

Create a comprehensive daily care plan with specific time-based tasks. Include:
1. Medication administration times with specific instructions
2. Vital signs monitoring schedule
3. Meal times and dietary considerations
4. Physical activity or therapy sessions
5. Personal care tasks (bathing, grooming, etc.)
6. Rest periods
7. Any condition-specific care requirements

Return ONLY a JSON object with this exact structure (no other text):

{
  "sopSteps": [
    {
      "stepOrder": 1,
      "timeLabel": "07:00 AM",
      "taskTitle": "Morning Medication",
      "taskDescription": "Administer [medicine name] with water before breakfast. Monitor for any side effects."
    },
    {
      "stepOrder": 2,
      "timeLabel": "07:30 AM",
      "taskTitle": "Breakfast",
      "taskDescription": "Provide balanced breakfast. Ensure adequate hydration."
    }
  ]
}

Instructions:
- Create 8-12 tasks covering a full day (morning to night)
- Use specific times (e.g., "07:00 AM", "12:00 PM", "08:00 PM")
- Make task titles concise (3-5 words)
- Make descriptions detailed and actionable
- Include all medicines from the list
- Consider the patient's age and condition
- Add monitoring and safety checks
- Return ONLY the JSON object, no markdown or additional text
    `.trim();

    // Get Gemini model
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    console.log('Sending request to Gemini API...');
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    if (!text) {
      throw new Error('Empty response from Gemini API');
    }

    console.log('=== RAW RESPONSE (first 500 chars) ===');
    console.log(text.substring(0, 500));

    // Clean the response
    let cleanJson = text.trim();

    // Remove markdown code blocks
    if (cleanJson.includes('```')) {
      cleanJson = cleanJson
        .replace(/```json/g, '')
        .replace(/```JSON/g, '')
        .replace(/```/g, '')
        .trim();
    }

    // Find JSON object boundaries
    const jsonStart = cleanJson.indexOf('{');
    const jsonEnd = cleanJson.lastIndexOf('}') + 1;

    if (jsonStart === -1 || jsonEnd <= jsonStart) {
      console.error('No valid JSON found in response');
      console.error('Full response:', cleanJson);
      throw new Error('No valid JSON found in API response');
    }

    cleanJson = cleanJson.substring(jsonStart, jsonEnd);

    console.log('=== CLEANED JSON (first 500 chars) ===');
    console.log(cleanJson.substring(0, 500));

    // Parse JSON
    let sopResponse;
    try {
      sopResponse = JSON.parse(cleanJson);
    } catch (parseError) {
      console.error('JSON PARSE ERROR:', parseError);
      console.error('Failed JSON:', cleanJson.substring(0, 200));
      throw new Error('Could not parse AI response. Check logs for details.');
    }

    if (!sopResponse || !sopResponse.sopSteps || sopResponse.sopSteps.length === 0) {
      throw new Error('No SOP steps generated');
    }

    console.log('=== SUCCESS ===');
    console.log('Generated', sopResponse.sopSteps.length, 'steps');

    res.json({
      sopSteps: sopResponse.sopSteps,
      rawResponse: cleanJson
    });

  } catch (error) {
    console.error('=== ERROR GENERATING SOP ===');
    console.error('Error type:', error.constructor.name);
    console.error('Error message:', error.message);
    console.error('Stack:', error.stack);
    
    res.status(500).json({ 
      error: 'Failed to generate SOP',
      message: error.message 
    });
  }
});

// Create patient with medicines
router.post('/patients', async (req, res) => {
  try {
    const { userId, name, age, diseaseCondition, medicines } = req.body;

    // Validate input
    if (!userId || !name || !age || !diseaseCondition) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Insert patient
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .insert({
        user_id: userId,
        name,
        age,
        disease_condition: diseaseCondition
      })
      .select()
      .single();

    if (patientError) {
      console.error('Error creating patient:', patientError);
      return res.status(500).json({ error: 'Failed to create patient' });
    }

    // Insert medicines if provided
    if (medicines && medicines.length > 0) {
      const medicineRecords = medicines.map(med => ({
        patient_id: patient.id,
        medicine_name: med.medicineName,
        photo_url: med.photoUrl || null
      }));

      const { error: medicineError } = await supabase
        .from('patient_medicines')
        .insert(medicineRecords);

      if (medicineError) {
        console.error('Error creating medicines:', medicineError);
        // Continue anyway, patient is created
      }
    }

    res.json({ patient });
  } catch (error) {
    console.error('Error in POST /patients:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create SOP with steps
router.post('/sops', async (req, res) => {
  try {
    const {
      userId,
      patientId,
      title,
      description,
      steps,
      rawGeminiResponse,
      createdBy
    } = req.body;

    // Validate input
    if (!userId || !patientId || !title || !steps || !createdBy) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Insert SOP
    const { data: sop, error: sopError } = await supabase
      .from('sops')
      .insert({
        user_id: userId,
        patient_id: patientId,
        title,
        description: description || null,
        raw_gemini_response: rawGeminiResponse || null,
        status: 'active'
      })
      .select()
      .single();

    if (sopError) {
      console.error('Error creating SOP:', sopError);
      return res.status(500).json({ error: 'Failed to create SOP' });
    }

    // Insert SOP steps
    const stepRecords = steps.map(step => ({
      sop_id: sop.id,
      step_order: step.stepOrder,
      time_label: step.timeLabel,
      task_title: step.taskTitle,
      task_description: step.taskDescription
    }));

    const { data: insertedSteps, error: stepsError } = await supabase
      .from('sop_steps')
      .insert(stepRecords)
      .select();

    if (stepsError) {
      console.error('Error creating SOP steps:', stepsError);
      return res.status(500).json({ error: 'Failed to create SOP steps' });
    }

    res.json({
      sop: {
        ...sop,
        steps: insertedSteps
      }
    });
  } catch (error) {
    console.error('Error in POST /sops:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get SOPs for a user (regular users - shows SOPs they created)
router.get('/sops/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const { data: sops, error } = await supabase
      .from('sops')
      .select(`
        *,
        patients (
          id,
          name,
          age,
          disease_condition
        ),
        sop_steps (
          id,
          step_order,
          time_label,
          task_title,
          task_description,
          is_completed
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching SOPs:', error);
      return res.status(500).json({ error: 'Failed to fetch SOPs' });
    }

    res.json({ sops });
  } catch (error) {
    console.error('Error in GET /sops/user/:userId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get ALL SOPs for caregivers (shows all SOPs in database)
router.get('/sops/all', async (req, res) => {
  try {
    const { data: sops, error } = await supabase
      .from('sops')
      .select(`
        *,
        patients (
          id,
          name,
          age,
          disease_condition
        ),
        sop_steps (
          id,
          step_order,
          time_label,
          task_title,
          task_description,
          is_completed
        )
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching all SOPs:', error);
      return res.status(500).json({ error: 'Failed to fetch SOPs' });
    }

    console.log(`Fetched ${sops.length} SOPs for caregiver`);
    res.json({ sops });
  } catch (error) {
    console.error('Error in GET /sops/all:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get single SOP with details
router.get('/sops/:sopId', async (req, res) => {
  try {
    const { sopId } = req.params;

    const { data: sop, error } = await supabase
      .from('sops')
      .select(`
        *,
        patients (
          id,
          name,
          age,
          disease_condition,
          patient_medicines (
            id,
            medicine_name,
            photo_url
          )
        ),
        sop_steps (
          id,
          step_order,
          time_label,
          task_title,
          task_description,
          is_completed,
          completed_at
        )
      `)
      .eq('id', sopId)
      .single();

    if (error) {
      console.error('Error fetching SOP:', error);
      return res.status(404).json({ error: 'SOP not found' });
    }

    res.json({ sop });
  } catch (error) {
    console.error('Error in GET /sops/:sopId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update SOP step
router.patch('/sops/steps/:stepId', async (req, res) => {
  try {
    const { stepId } = req.params;
    const { timeLabel, taskTitle, taskDescription } = req.body;

    const updateData = {};
    if (timeLabel !== undefined) updateData.time_label = timeLabel;
    if (taskTitle !== undefined) updateData.task_title = taskTitle;
    if (taskDescription !== undefined) updateData.task_description = taskDescription;

    const { data: step, error } = await supabase
      .from('sop_steps')
      .update(updateData)
      .eq('id', stepId)
      .select()
      .single();

    if (error) {
      console.error('Error updating SOP step:', error);
      return res.status(500).json({ error: 'Failed to update SOP step' });
    }

    res.json({ step });
  } catch (error) {
    console.error('Error in PATCH /sops/steps/:stepId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete SOP step
router.delete('/sops/steps/:stepId', async (req, res) => {
  try {
    const { stepId } = req.params;

    const { error } = await supabase
      .from('sop_steps')
      .delete()
      .eq('id', stepId);

    if (error) {
      console.error('Error deleting SOP step:', error);
      return res.status(500).json({ error: 'Failed to delete SOP step' });
    }

    res.json({ message: 'SOP step deleted successfully' });
  } catch (error) {
    console.error('Error in DELETE /sops/steps/:stepId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mark SOP step as completed
router.patch('/sops/steps/:stepId/complete', async (req, res) => {
  try {
    const { stepId } = req.params;
    const { isCompleted } = req.body;

    const { data: step, error } = await supabase
      .from('sop_steps')
      .update({
        is_completed: isCompleted,
        completed_at: isCompleted ? new Date().toISOString() : null,
        validation_status: isCompleted ? 'approved' : 'pending',
        validation_message: isCompleted ? 'Task completed on time' : null
      })
      .eq('id', stepId)
      .select()
      .single();

    if (error) {
      console.error('Error updating step completion:', error);
      return res.status(500).json({ error: 'Failed to update step completion' });
    }

    res.json({ step });
  } catch (error) {
    console.error('Error in PATCH /sops/steps/:stepId/complete:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mark SOP step as rejected
router.patch('/sops/steps/:stepId/reject', async (req, res) => {
  try {
    const { stepId } = req.params;
    const { rejectionReason } = req.body;

    const { data: step, error } = await supabase
      .from('sop_steps')
      .update({
        validation_status: 'rejected',
        validation_message: rejectionReason || 'Time mismatch',
        rejected_at: new Date().toISOString(),
        rejection_count: supabase.raw('rejection_count + 1'),
        is_completed: false
      })
      .eq('id', stepId)
      .select()
      .single();

    if (error) {
      console.error('Error marking step as rejected:', error);
      return res.status(500).json({ error: 'Failed to mark step as rejected' });
    }

    res.json({ step });
  } catch (error) {
    console.error('Error in PATCH /sops/steps/:stepId/reject:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get patients assigned to a caregiver
router.get('/caregiver/:caregiverId/patients', async (req, res) => {
  try {
    const { caregiverId } = req.params;

    const { data: assignments, error } = await supabase
      .from('caregiver_assignments')
      .select(`
        *,
        patients (
          id,
          name,
          age,
          disease_condition,
          created_at,
          patient_medicines (
            id,
            medicine_name,
            photo_url
          )
        )
      `)
      .eq('caregiver_id', caregiverId)
      .eq('status', 'active')
      .order('assigned_at', { ascending: false });

    if (error) {
      console.error('Error fetching assigned patients:', error);
      return res.status(500).json({ error: 'Failed to fetch assigned patients' });
    }

    // Extract patient data
    const patients = assignments.map(a => a.patients);

    res.json({ patients });
  } catch (error) {
    console.error('Error in GET /caregiver/:caregiverId/patients:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get ALL patients for caregivers (shows all patients in database)
router.get('/patients/all', async (req, res) => {
  try {
    const { data: patients, error } = await supabase
      .from('patients')
      .select(`
        id,
        name,
        age,
        disease_condition,
        created_at,
        patient_medicines (
          id,
          medicine_name,
          photo_url
        )
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching all patients:', error);
      return res.status(500).json({ error: 'Failed to fetch patients' });
    }

    console.log(`Fetched ${patients.length} patients for caregiver`);
    res.json({ patients });
  } catch (error) {
    console.error('Error in GET /patients/all:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Assign caregiver to patient
router.post('/caregiver/assign', async (req, res) => {
  try {
    const { caregiverId, patientId, assignedBy, notes } = req.body;

    if (!caregiverId || !patientId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if assignment already exists
    const { data: existing } = await supabase
      .from('caregiver_assignments')
      .select('id, status')
      .eq('caregiver_id', caregiverId)
      .eq('patient_id', patientId)
      .single();

    if (existing) {
      // If exists but inactive, reactivate it
      if (existing.status === 'inactive') {
        const { data: updated, error } = await supabase
          .from('caregiver_assignments')
          .update({ status: 'active', assigned_at: new Date().toISOString() })
          .eq('id', existing.id)
          .select()
          .single();

        if (error) {
          console.error('Error reactivating assignment:', error);
          return res.status(500).json({ error: 'Failed to reactivate assignment' });
        }

        return res.json({ assignment: updated, message: 'Assignment reactivated' });
      }

      return res.status(409).json({ error: 'Assignment already exists' });
    }

    // Create new assignment
    const { data: assignment, error } = await supabase
      .from('caregiver_assignments')
      .insert({
        caregiver_id: caregiverId,
        patient_id: patientId,
        assigned_by: assignedBy || null,
        notes: notes || null,
        status: 'active'
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating assignment:', error);
      return res.status(500).json({ error: 'Failed to create assignment' });
    }

    res.json({ assignment });
  } catch (error) {
    console.error('Error in POST /caregiver/assign:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Remove caregiver assignment
router.delete('/caregiver/assign/:assignmentId', async (req, res) => {
  try {
    const { assignmentId } = req.params;

    // Soft delete by setting status to inactive
    const { data: assignment, error } = await supabase
      .from('caregiver_assignments')
      .update({ status: 'inactive' })
      .eq('id', assignmentId)
      .select()
      .single();

    if (error) {
      console.error('Error removing assignment:', error);
      return res.status(500).json({ error: 'Failed to remove assignment' });
    }

    res.json({ assignment, message: 'Assignment removed successfully' });
  } catch (error) {
    console.error('Error in DELETE /caregiver/assign/:assignmentId:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
