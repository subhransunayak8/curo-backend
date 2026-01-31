const { supabase } = require('../config/supabase');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const config = require('../config/config');

class AuthService {
  async register(email, password, name = null) {
    try {
      console.log(`Registering new user: ${email}`);

      // Check if user already exists
      const { data: existingUser } = await supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .single();

      if (existingUser) {
        throw new Error('User with this email already exists');
      }

      // Hash password
      const passwordHash = await bcrypt.hash(password, 10);

      // Create user
      const { data: newUser, error } = await supabase
        .from('users')
        .insert({
          email,
          password_hash: passwordHash,
          full_name: name,
          role: 'user',
          created_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;

      console.log(`User registered successfully: ${email}`);

      // Create JWT token
      const accessToken = this.createAccessToken(newUser.id, newUser.email);

      return {
        access_token: accessToken,
        token_type: 'bearer',
        user_id: newUser.id,
        email: newUser.email,
        name: newUser.full_name
      };
    } catch (error) {
      console.error('Error registering user:', error);
      throw error;
    }
  }

  async login(email, password) {
    try {
      console.log(`Login attempt for: ${email}`);

      // Get user by email
      const { data: user, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', email)
        .single();

      if (error || !user) {
        throw new Error('Invalid email or password');
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);

      if (!isValidPassword) {
        throw new Error('Invalid email or password');
      }

      console.log(`User logged in successfully: ${email}`);

      // Create JWT token
      const accessToken = this.createAccessToken(user.id, user.email);

      return {
        access_token: accessToken,
        token_type: 'bearer',
        user_id: user.id,
        email: user.email,
        name: user.full_name
      };
    } catch (error) {
      console.error('Error logging in:', error);
      throw error;
    }
  }

  createAccessToken(userId, email) {
    return jwt.sign(
      { sub: userId, email },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );
  }

  verifyToken(token) {
    try {
      return jwt.verify(token, config.jwt.secret);
    } catch (error) {
      return null;
    }
  }
}

module.exports = new AuthService();
