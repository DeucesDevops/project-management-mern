import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { HiOutlineArrowLeft, HiOutlinePlus, HiOutlineTrash } from 'react-icons/hi';
import api from '../services/api';

interface Project {
    _id: string; title: string; description: string; status: string; priority: string;
    owner: { name: string }; members: { _id: string; name: string }[];
    deadline: string | null;
}
interface Task {
    _id: string; title: string; description: string; status: string; priority: string;
    assignee?: { _id: string; name: string } | null; dueDate: string | null;
}

const statusCols = [
    { key: 'todo', label: 'To Do', dot: 'bg-[var(--color-text-muted)]' },
    { key: 'in-progress', label: 'In Progress', dot: 'bg-[var(--color-info)]' },
    { key: 'review', label: 'Review', dot: 'bg-[var(--color-warning)]' },
    { key: 'done', label: 'Done', dot: 'bg-[var(--color-success)]' },
];

const priorityColor: Record<string, string> = {
    low: 'bg-[var(--color-priority-low)]', medium: 'bg-[var(--color-priority-medium)]',
    high: 'bg-[var(--color-priority-high)]', critical: 'bg-[var(--color-priority-critical)]',
};

const ProjectDetail = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [project, setProject] = useState<Project | null>(null);
    const [tasks, setTasks] = useState<Task[]>([]);
    const [loading, setLoading] = useState(true);
    const [showAddTask, setShowAddTask] = useState(false);
    const [taskForm, setTaskForm] = useState({ title: '', description: '', priority: 'medium', status: 'todo', dueDate: '' });

    const fetchData = async () => {
        try {
            const [pRes, tRes] = await Promise.all([api.get(`/projects/${id}`), api.get(`/projects/${id}/tasks`)]);
            setProject(pRes.data);
            setTasks(tRes.data);
        } catch (e) { console.error(e); }
        finally { setLoading(false); }
    };
    useEffect(() => { fetchData(); }, [id]);

    const createTask = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await api.post('/tasks', { ...taskForm, project: id, dueDate: taskForm.dueDate || null });
            setShowAddTask(false);
            setTaskForm({ title: '', description: '', priority: 'medium', status: 'todo', dueDate: '' });
            fetchData();
        } catch (e) { console.error(e); }
    };

    const updateTaskStatus = async (taskId: string, status: string) => {
        try { await api.patch(`/tasks/${taskId}/status`, { status }); fetchData(); } catch (e) { console.error(e); }
    };

    const deleteTask = async (taskId: string) => {
        try { await api.delete(`/tasks/${taskId}`); fetchData(); } catch (e) { console.error(e); }
    };

    if (loading) return <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-[var(--color-border)] border-t-[var(--color-accent)] rounded-full animate-[spin_0.8s_linear_infinite]" /></div>;
    if (!project) return <div className="p-8 text-[var(--color-text-muted)]">Project not found.</div>;

    const inputCls = "w-full input-base focus:input-focus";

    return (
        <div className="p-8 max-w-[1400px] animate-[fade-in_0.3s_ease]">
            {/* Header */}
            <div className="flex items-center gap-4 mb-6">
                <button onClick={() => navigate('/projects')} className="w-9 h-9 flex items-center justify-center rounded-[10px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] text-[var(--color-text-secondary)] cursor-pointer hover:bg-[var(--color-bg-glass-hover)] transition-all">
                    <HiOutlineArrowLeft />
                </button>
                <div className="flex-1">
                    <h1 className="text-[28px] font-extrabold tracking-tight">{project.title}</h1>
                    <p className="text-sm text-[var(--color-text-secondary)]">{project.description || 'No description'}</p>
                </div>
                <button onClick={() => setShowAddTask(true)} className="inline-flex items-center gap-2 px-5 py-2.5 rounded-[10px] text-sm font-semibold btn-primary hover:btn-primary-hover transition-all cursor-pointer border-none">
                    <HiOutlinePlus /> Add Task
                </button>
            </div>

            {/* Kanban Columns */}
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
                {statusCols.map((col) => {
                    const colTasks = tasks.filter(t => t.status === col.key);
                    return (
                        <div key={col.key} className="bg-[var(--color-bg-secondary)] rounded-2xl p-4 border border-[var(--color-border)]">
                            <div className="flex items-center gap-2 mb-4">
                                <div className={`w-2.5 h-2.5 rounded-full ${col.dot}`} />
                                <h3 className="text-sm font-bold text-[var(--color-text-secondary)]">{col.label}</h3>
                                <span className="ml-auto text-xs text-[var(--color-text-muted)] bg-[var(--color-bg-glass)] px-2 py-0.5 rounded-full">{colTasks.length}</span>
                            </div>
                            <div className="flex flex-col gap-2 min-h-[100px]">
                                {colTasks.map((task) => (
                                    <div key={task._id} className="bg-[var(--color-bg-card)] border border-[var(--color-border)] rounded-xl p-3.5 hover:border-[var(--color-border-active)] transition-all group">
                                        <div className="flex items-start justify-between mb-2">
                                            <div className="flex items-center gap-2">
                                                <div className={`w-2 h-2 rounded-full ${priorityColor[task.priority]}`} title={task.priority} />
                                                <h4 className="text-sm font-semibold">{task.title}</h4>
                                            </div>
                                            <button onClick={() => deleteTask(task._id)} className="opacity-0 group-hover:opacity-100 text-[var(--color-text-muted)] hover:text-[var(--color-danger)] transition-all cursor-pointer bg-transparent border-none">
                                                <HiOutlineTrash className="text-sm" />
                                            </button>
                                        </div>
                                        {task.description && <p className="text-xs text-[var(--color-text-muted)] mb-2 line-clamp-2">{task.description}</p>}
                                        <div className="flex items-center justify-between">
                                            <select value={task.status} onChange={(e) => updateTaskStatus(task._id, e.target.value)}
                                                className="text-[11px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] rounded-md px-2 py-1 text-[var(--color-text-secondary)] outline-none cursor-pointer">
                                                {statusCols.map(s => <option key={s.key} value={s.key}>{s.label}</option>)}
                                            </select>
                                            {task.assignee && (
                                                <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-[10px] font-bold text-white" title={task.assignee.name}>
                                                    {task.assignee.name.charAt(0).toUpperCase()}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    );
                })}
            </div>

            {/* Add Task Modal */}
            {showAddTask && (
                <div className="fixed inset-0 bg-black/60 backdrop-blur-[4px] flex items-center justify-center z-[1000] animate-[fade-in_0.2s_ease]" onClick={() => setShowAddTask(false)}>
                    <div className="bg-[var(--color-bg-secondary)] border border-[var(--color-border)] rounded-[20px] p-8 w-[90%] max-w-[520px] animate-[slide-up_0.3s_ease]" onClick={(e) => e.stopPropagation()}>
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-bold">Add Task</h2>
                            <button onClick={() => setShowAddTask(false)} className="w-9 h-9 flex items-center justify-center rounded-[10px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] text-[var(--color-text-secondary)] cursor-pointer hover:bg-[var(--color-bg-glass-hover)]">✕</button>
                        </div>
                        <form onSubmit={createTask} className="flex flex-col gap-4">
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Title</label>
                                <input className={inputCls} placeholder="Task title" value={taskForm.title} onChange={(e) => setTaskForm({ ...taskForm, title: e.target.value })} required />
                            </div>
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Description</label>
                                <textarea className={`${inputCls} min-h-[80px] resize-y`} placeholder="Task description..." value={taskForm.description} onChange={(e) => setTaskForm({ ...taskForm, description: e.target.value })} />
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div className="flex flex-col gap-1.5">
                                    <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Priority</label>
                                    <select className={inputCls} value={taskForm.priority} onChange={(e) => setTaskForm({ ...taskForm, priority: e.target.value })}>
                                        <option value="low">Low</option><option value="medium">Medium</option><option value="high">High</option><option value="critical">Critical</option>
                                    </select>
                                </div>
                                <div className="flex flex-col gap-1.5">
                                    <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Due Date</label>
                                    <input type="date" className={inputCls} value={taskForm.dueDate} onChange={(e) => setTaskForm({ ...taskForm, dueDate: e.target.value })} />
                                </div>
                            </div>
                            <div className="flex justify-end gap-2 mt-4">
                                <button type="button" onClick={() => setShowAddTask(false)} className="px-5 py-2.5 rounded-[10px] text-sm font-semibold bg-[var(--color-bg-glass)] text-[var(--color-text-primary)] border border-[var(--color-border)] cursor-pointer hover:bg-[var(--color-bg-glass-hover)]">Cancel</button>
                                <button type="submit" className="px-5 py-2.5 rounded-[10px] text-sm font-semibold btn-primary hover:btn-primary-hover transition-all cursor-pointer border-none">Add Task</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ProjectDetail;
