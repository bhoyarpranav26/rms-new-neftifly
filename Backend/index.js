const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const db = require("./db");
const path = require('path');
require("dotenv").config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
// Support comma-separated CORS origins in the env var (e.g. "http://localhost:5173,http://localhost:4173")
const corsOrigins = (process.env.CORS_ORIGIN || "http://localhost:5173").split(',').map(s => s.trim());
app.use(cors({
  origin: function (origin, callback) {
    // allow non-browser requests (e.g., curl, Postman) with no origin
    if (!origin) return callback(null, true);
    if (corsOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  }
}));
app.use(bodyParser.json());

// ==========================
// ✅ Postgres (RDS) Connection
// ==========================
// Initialize the DB (creates tables if needed)
db.init()
  .then(() => console.log('✅ Postgres DB initialized'))
  .catch(err => console.error('❌ Postgres init error:', err));


// ==========================
// ✅ Routes Import
// ==========================
console.log("📌 Loading auth routes...");
const authRoutes = require("./routes/authRoutes");

app.use("/api/auth", authRoutes);
console.log("📌 Auth routes mounted at /api/auth");

// Root test
app.get("/", (req, res) => {
  res.send("Backend is running!");
});

// ==========================
// Start Server
// ==========================
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
