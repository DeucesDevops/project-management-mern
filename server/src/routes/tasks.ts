import { Router, Response } from 'express';
import Task from '../models/Task';
import Project from '../models/Project';
import auth from '../middleware/auth';
import { AuthRequest } from '../types';

const router = Router();

// GET /api/tasks
router.get('/', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const userProjects = await Project.find({
            $or: [{ owner: req.user!._id }, { members: req.user!._id }]
        }).select('_id');

        const projectIds = userProjects.map(p => p._id);

        const tasks = await Task.find({
            $or: [
                { assignee: req.user!._id },
                { project: { $in: projectIds } }
            ]
        })
            .populate('assignee', 'name email')
            .populate('project', 'title')
            .sort({ createdAt: -1 });

        res.json(tasks);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// POST /api/tasks
router.post('/', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { title, description, status, priority, project, assignee, dueDate } = req.body;

        const task = await Task.create({
            title,
            description,
            status,
            priority,
            project,
            assignee: assignee || null,
            dueDate: dueDate || null
        });

        const populated = await task.populate([
            { path: 'assignee', select: 'name email' },
            { path: 'project', select: 'title' }
        ]);

        res.status(201).json(populated);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// GET /api/tasks/:id
router.get('/:id', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const task = await Task.findById(req.params.id)
            .populate('assignee', 'name email')
            .populate('project', 'title');

        if (!task) {
            res.status(404).json({ message: 'Task not found' });
            return;
        }

        res.json(task);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// PUT /api/tasks/:id
router.put('/:id', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const task = await Task.findById(req.params.id);
        if (!task) {
            res.status(404).json({ message: 'Task not found' });
            return;
        }

        const { title, description, status, priority, assignee, dueDate } = req.body;
        if (title !== undefined) task.title = title;
        if (description !== undefined) task.description = description;
        if (status !== undefined) task.status = status;
        if (priority !== undefined) task.priority = priority;
        if (assignee !== undefined) task.assignee = assignee;
        if (dueDate !== undefined) task.dueDate = dueDate;

        const updated = await task.save();
        const populated = await updated.populate([
            { path: 'assignee', select: 'name email' },
            { path: 'project', select: 'title' }
        ]);

        res.json(populated);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// PATCH /api/tasks/:id/status
router.patch('/:id/status', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { status } = req.body;
        const task = await Task.findByIdAndUpdate(
            req.params.id,
            { status },
            { new: true, runValidators: true }
        )
            .populate('assignee', 'name email')
            .populate('project', 'title');

        if (!task) {
            res.status(404).json({ message: 'Task not found' });
            return;
        }

        res.json(task);
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// DELETE /api/tasks/:id
router.delete('/:id', auth, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const task = await Task.findById(req.params.id);
        if (!task) {
            res.status(404).json({ message: 'Task not found' });
            return;
        }

        await task.deleteOne();
        res.json({ message: 'Task deleted' });
    } catch (error) {
        const err = error as Error;
        res.status(500).json({ message: 'Server error', error: err.message });
    }
});

export default router;
