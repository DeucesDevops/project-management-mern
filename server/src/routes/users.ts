import { Router, Response } from 'express';
import User from '../models/User';
import auth from '../middleware/auth';
import { AuthRequest } from '../types';

const router = Router();

// GET /api/users
router.get('/', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const users = await User.find().select('-password').sort({ name: 1 });
        res.json(users);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

export default router;
