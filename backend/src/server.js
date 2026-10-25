require('dotenv').config();

const app = require('./app');
const pool = require('./config/db');

const PORT = Number(process.env.PORT || 5000);

async function startServer() {
  try {
    await pool.query('SELECT 1');

    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`Digital Ekub API running on port ${PORT}`);
      console.log('PostgreSQL connection successful');
    });

    server.on('error', async (error) => {
      console.error('Server error:', error.message);
      await pool.end();
      process.exitCode = 1;
    });
  } catch (error) {
    console.error('Unable to connect to PostgreSQL:', error.message);
    await pool.end();
    process.exitCode = 1;
  }
}

startServer();
