import { Request } from 'express';
import { Document, Types } from 'mongoose';

export interface IUser extends Document {
    _id: Types.ObjectId;
    name: string;
    email: string;
    password: string;
    role: 'admin' | 'manager' | 'member';
    avatar: string;
    createdAt: Date;
    updatedAt: Date;
    matchPassword(enteredPassword: string): Promise<boolean>;
}

export interface IProject extends Document {
    _id: Types.ObjectId;
    title: string;
    description: string;
    status: 'active' | 'completed' | 'on-hold';
    priority: 'low' | 'medium' | 'high' | 'critical';
    owner: Types.ObjectId;
    members: Types.ObjectId[];
    deadline: Date | null;
    createdAt: Date;
    updatedAt: Date;
}

export interface ITask extends Document {
    _id: Types.ObjectId;
    title: string;
    description: string;
    status: 'todo' | 'in-progress' | 'review' | 'done';
    priority: 'low' | 'medium' | 'high' | 'critical';
    project: Types.ObjectId;
    assignee: Types.ObjectId | null;
    dueDate: Date | null;
    createdAt: Date;
    updatedAt: Date;
}

export interface AuthRequest extends Request {
    user?: IUser;
}
