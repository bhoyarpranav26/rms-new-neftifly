const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || process.env.RDS_HOST || 'localhost',
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 5432,
  user: process.env.DB_USER || 'restom_admin',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'restom_db',
  max: 10,
  idleTimeoutMillis: 30000,
});

async function init() {
  // create users table if not exists
  const createQuery = `
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      phone TEXT NOT NULL,
      password TEXT NOT NULL,
      otp TEXT,
      otp_expires TIMESTAMP,
      verified BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT now()
    );
  `;
  await pool.query(createQuery);
}

module.exports = {
  query: (text, params) => pool.query(text, params),
  init,
  pool,
};
