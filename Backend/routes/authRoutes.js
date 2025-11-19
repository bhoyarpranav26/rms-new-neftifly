const express = require("express");
const router = express.Router();
const db = require("../db");
const nodemailer = require("nodemailer");

// Helper to send OTP email
async function sendOtpEmail(to, otp) {
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: process.env.EMAIL_USER,
    to,
    subject: "Your OTP Code",
    text: `Your OTP is ${otp}. It expires in 10 minutes.`,
  });
}

// ------------------ SIGNUP ------------------
router.post("/signup", async (req, res) => {
  try {
    const { name, email, phone, number, password } = req.body;
    const finalPhone = phone || number;

    if (!name || !email || !finalPhone || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const existingR = await db.query("SELECT * FROM users WHERE email=$1", [
      email,
    ]);
    const existingUser = existingR.rows[0];

    if (existingUser && existingUser.verified) {
      return res.status(400).json({ message: "Email already registered" });
    }

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

    let user;
    if (existingUser) {
      const r = await db.query(
        "UPDATE users SET otp=$1, otp_expires=$2 WHERE email=$3 RETURNING *",
        [otp, otpExpiry, email]
      );
      user = r.rows[0];
    } else {
      const r = await db.query(
        "INSERT INTO users(name,email,phone,password,otp,otp_expires) VALUES($1,$2,$3,$4,$5,$6) RETURNING *",
        [name, email, finalPhone, password, otp, otpExpiry]
      );
      user = r.rows[0];
    }

    // send OTP
    await sendOtpEmail(email, otp);

    res.status(200).json({ message: "OTP sent successfully" });
  } catch (err) {
    console.error("Signup error:", err);
    res.status(500).json({ message: "Signup failed", error: err.message });
  }
});

// ------------------ VERIFY OTP ------------------
router.post("/verify-otp", async (req, res) => {
  try {
    const { email, otp } = req.body;
    const r = await db.query("SELECT * FROM users WHERE email=$1", [email]);
    const user = r.rows[0];

    if (!user) return res.status(400).json({ message: "User not found" });
    if (user.verified) return res.status(400).json({ message: "Already verified" });
    if (user.otp !== otp) return res.status(400).json({ message: "Invalid OTP" });
    if (new Date() > user.otp_expires) return res.status(400).json({ message: "OTP expired" });

    await db.query("UPDATE users SET verified=true, otp=null, otp_expires=null WHERE email=$1", [email]);
    res.status(200).json({ message: "Account verified successfully!" });
  } catch (err) {
    console.error("OTP Verify error:", err);
    res.status(500).json({ message: "OTP verification failed" });
  }
});

// ------------------ LOGIN ------------------
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const r = await db.query("SELECT * FROM users WHERE email=$1", [email]);
    const user = r.rows[0];

    if (!user) return res.status(400).json({ message: "User not found" });
    if (!user.verified) return res.status(400).json({ message: "Please verify your OTP first" });
    if (user.password !== password) return res.status(400).json({ message: "Incorrect password" });

    res.status(200).json({
      message: "Login successful",
      user: {
        name: user.name,
        email: user.email,
        phone: user.phone,
      },
    });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Login failed" });
  }
});

module.exports = router;
