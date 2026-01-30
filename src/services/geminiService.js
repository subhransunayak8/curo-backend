const { GoogleGenerativeAI } = require('@google/generative-ai');
const config = require('../config/config');

class GeminiService {
  constructor() {
    if (!config.gemini.apiKey) {
      console.warn('Gemini API key not configured');
      this.genAI = null;
      this.model = null;
      return;
    }

    this.genAI = new GoogleGenerativeAI(config.gemini.apiKey);
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-pro' });
  }

  async analyzePrescription(medicineText) {
    if (!this.model) {
      throw new Error('Gemini AI is not configured');
    }

    const prompt = `Analyze this prescription and extract medicine information in JSON format:

${medicineText}

Return ONLY a valid JSON object with this structure:
{
  "medicines": [
    {
      "name": "Medicine name",
      "dosage": "Dosage amount",
      "frequency": "How often to take",
      "duration": "How long to take",
      "instructions": "Special instructions"
    }
  ],
  "sop_schedule": [
    {
      "time": "HH:MM",
      "task": "Task description",
      "medicines": ["Medicine names"]
    }
  ]
}`;

    try {
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      // Extract JSON from response
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('No valid JSON found in response');
      }

      const analysisData = JSON.parse(jsonMatch[0]);
      return analysisData;
    } catch (error) {
      console.error('Error analyzing prescription:', error);
      throw error;
    }
  }
}

module.exports = new GeminiService();
