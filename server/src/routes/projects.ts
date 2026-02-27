import { Router, Response } from 'express';
import Project from '../models/Project';
import Task from '../models/Task';
import auth from '../middleware/auth';
import { AuthRequest } from '../types';

const router = Router();

// GET /api/projects
router.get('/', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const projects = await Project.find({
            $or: [{ owner: req.user!._id }, { members: req.user!._id }]
        })
            .populate('owner', 'name email')
            .populate('members', 'name email')
            .sort({ createdAt: -1 });

        res.json(projects);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// POST /api/projects
router.post('/', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { title, description, status, priority, members, deadline } = req.body;

        const project = await Project.create({
            title,
            description,
            status,
            priority,
            owner: req.user!._id,
            members: members || [],
            deadline: deadline || null
        });

        const populated = await project.populate([
            { path: 'owner', select: 'name email' },
            { path: 'members', select: 'name email' }
        ]);

        res.status(201).json(populated);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// GET /api/projects/:id
router.get('/:id', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const project = await Project.findById(req.params.id)
            .populate('owner', 'name email')
            .populate('members', 'name email');

        if (!project) {
            res.status(404).json({ message: 'Project not found' });
            return;
        }

        res.json(project);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// PUT /api/projects/:id
router.put('/:id', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const project = await Project.findById(req.params.id);
        if (!project) {
            res.status(404).json({ message: 'Project not found' });
            return;
        }

        const { title, description, status, priority, members, deadline } = req.body;
        if (title !== undefined) project.title = title;
        if (description !== undefined) project.description = description;
        if (status !== undefined) project.status = status;
        if (priority !== undefined) project.priority = priority;
        if (members !== undefined) project.members = members;
        if (deadline !== undefined) project.deadline = deadline;

        const updated = await project.save();
        const populated = await updated.populate([
            { path: 'owner', select: 'name email' },
            { path: 'members', select: 'name email' }
        ]);

        res.json(populated);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// DELETE /api/projects/:id
router.delete('/:id', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const project = await Project.findById(req.params.id);
        if (!project) {
            res.status(404).json({ message: 'Project not found' });
            return;
        }

        await Task.deleteMany({ project: project._id });
        await project.deleteOne();

        res.json({ message: 'Project and associated tasks deleted' });
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// GET /api/projects/:id/tasks
router.get('/:id/tasks', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const tasks = await Task.find({ project: req.params.id })
            .populate('assignee', 'name email')
            .sort({ createdAt: -1 });

        res.json(tasks);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

export default router;
