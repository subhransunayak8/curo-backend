const { createClient } = require('@supabase/supabase-js');
const config = require('./config');

if (!config.supabase.url || !config.supabase.key) {
  throw new Error('Supabase URL and Key are required');
}

const supabase = createClient(
  config.supabase.url,
  config.supabase.key
);

const supabaseAdmin = createClient(
  config.supabase.url,
  config.supabase.serviceRoleKey
);

module.exports = { supabase, supabaseAdmin };
