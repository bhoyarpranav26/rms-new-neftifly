// controllers/authController.js
const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");

const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// Configure transporter using env vars. Support SendGrid (API key) or any SMTP server.
let transporter;
if (process.env.SENDGRID_API_KEY) {
  // SendGrid SMTP via nodemailer using API key (user 'apikey')
  transporter = nodemailer.createTransport({
    service: 'SendGrid',
    auth: { user: 'apikey', pass: process.env.SENDGRID_API_KEY },
  });
} else {
  const smtpHost = process.env.SMTP_HOST || 'smtp.gmail.com';
  const smtpPort = process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT, 10) : 587;
  const smtpSecure = (process.env.SMTP_SECURE === 'true');

  transporter = nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpSecure,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });
}

// SIGNUP: save user (unverified) and send OTP by email
exports.signup = async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    if (!name || !email || !phone || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    // check existing
    let existing = await User.findOne({ email });
    if (existing && existing.verified) {
      return res.status(400).json({ message: "Email already registered" });
    }

    const hashed = await bcrypt.hash(password, 10);
    const otp = generateOTP();
    const otpExpiry = Date.now() + 10 * 60 * 1000; // 10 minutes

    let user;
    if (existing) {
      user = await User.findOneAndUpdate({ email }, {
        name, phone, password: hashed, otp, otpExpires: otpExpiry, verified: false
      }, { new: true });
    } else {
      user = new User({ name, email, phone, password: hashed, otp, otpExpires: otpExpiry });
      await user.save();
    }

    // send email
    try {
      await transporter.sendMail({
        from: process.env.EMAIL_FROM || process.env.EMAIL_USER,
        to: email,
        subject: process.env.EMAIL_SUBJECT || "Your OTP",
        text: `Hello ${name},\n\nYour OTP is ${otp}. It expires in 10 minutes.\n\nIf you didn't request this, ignore this mail.`,
      });
    } catch (mailErr) {
      console.error('Error sending OTP email:', mailErr);
      return res.status(500).json({ message: 'Failed to send OTP email', error: mailErr.message });
    }

    return res.status(200).json({ message: "OTP sent to email" });
  } catch (err) {
    console.error("Signup error:", err);
    // handle validation error (like phone required)
    return res.status(500).json({ message: "Signup failed", error: err.message });
  }
};

// VERIFY OTP
exports.verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ message: "Email and OTP required" });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    if (user.verified) return res.status(400).json({ message: "User already verified" });
    if (user.otp !== otp) return res.status(400).json({ message: "Invalid OTP" });
    if (Date.now() > user.otpExpires) return res.status(400).json({ message: "OTP expired" });

    user.verified = true;
    user.otp = undefined;
    user.otpExpires = undefined;
    await user.save();

    return res.status(200).json({ message: "Account verified successfully" });
  } catch (err) {
    console.error("Verify OTP error:", err);
    return res.status(500).json({ message: "OTP verification failed" });
  }
};

// LOGIN
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: "Email and password required" });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });
    if (!user.verified) return res.status(403).json({ message: "Email not verified" });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(400).json({ message: "Invalid credentials" });

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET || "secret", { expiresIn: "7d" });

    return res.status(200).json({
      message: "Login successful",
      token,
      user: { id: user._id, name: user.name, email: user.email, phone: user.phone }
    });
  } catch (err) {
    console.error("Login error:", err);
    return res.status(500).json({ message: "Login failed" });
  }
};

// PROFILE (protected) - small helper for route usage
exports.getProfile = async (req, res) => {
  try {
    const userId = req.userId; // from middleware
    const user = await User.findById(userId).select("-password -otp -otpExpires");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json({ user });
  } catch (err) {
    console.error("GetProfile error:", err);
    res.status(500).json({ message: "Failed to fetch profile" });
  }
};
