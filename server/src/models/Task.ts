import mongoose, { Schema } from 'mongoose';
import { ITask } from '../types';

const taskSchema = new Schema<ITask>({
    title: {
        type: String,
        required: [true, 'Task title is required'],
        trim: true,
        maxlength: 200
    },
    description: {
        type: String,
        default: '',
        maxlength: 1000
    },
    status: {
        type: String,
        enum: ['todo', 'in-progress', 'review', 'done'],
        default: 'todo'
    },
    priority: {
        type: String,
        enum: ['low', 'medium', 'high', 'critical'],
        default: 'medium'
    },
    project: {
        type: Schema.Types.ObjectId,
        ref: 'Project',
        required: true
    },
    assignee: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        default: null
    },
    dueDate: {
        type: Date,
        default: null
    }
}, { timestamps: true });

export default mongoose.model<ITask>('Task', taskSchema);
