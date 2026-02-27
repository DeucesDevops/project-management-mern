import { Router, Response } from 'express';
import jwt from 'jsonwebtoken';
import { body, validationResult } from 'express-validator';
import User from '../models/User';
import auth from '../middleware/auth';
import { AuthRequest } from '../types';

const router = Router();

const generateToken = (id: string): string => {
    return jwt.sign({ id }, process.env.JWT_SECRET as string, { expiresIn: '30d' });
};

// POST /api/auth/register
router.post('/register', [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            res.status(400).json({ errors: errors.array() });
            return;
        }

        const { name, email, password } = req.body;

        const existingUser = await User.findOne({ email });
        if (existingUser) {
            res.status(400).json({ message: 'User already exists with this email' });
            return;
        }

        const user = await User.create({ name, email, password });

        res.status(201).json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            token: generateToken(user._id.toString())
        });
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// POST /api/auth/login
router.post('/login', [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required')
], async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            res.status(400).json({ errors: errors.array() });
            return;
        }

        const { email, password } = req.body;

        const user = await User.findOne({ email });
        if (!user || !(await user.matchPassword(password))) {
            res.status(401).json({ message: 'Invalid email or password' });
            return;
        }

        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            token: generateToken(user._id.toString())
        });
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// GET /api/auth/me
router.get('/me', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        res.json(req.user);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// PUT /api/auth/profile
router.put('/profile', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const user = await User.findById(req.user!._id);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        user.name = req.body.name || user.name;
        user.email = req.body.email || user.email;
        if (req.body.password) {
            user.password = req.body.password;
        }

        const updatedUser = await user.save();
        res.json({
            _id: updatedUser._id,
            name: updatedUser.name,
            email: updatedUser.email,
            role: updatedUser.role,
            token: generateToken(updatedUser._id.toString())
        });
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

export default router;
