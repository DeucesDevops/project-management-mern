import { useState, useEffect } from 'react';
import api from '../services/api';

interface Task {
    _id: string; title: string; description: string; status: string; priority: string;
    project?: { _id: string; title: string }; assignee?: { _id: string; name: string } | null;
    dueDate: string | null;
}

const statusCols = [
    { key: 'todo', label: 'To Do', dot: 'bg-[var(--color-text-muted)]', count_bg: 'bg-[rgba(106,106,138,0.2)]' },
    { key: 'in-progress', label: 'In Progress', dot: 'bg-[var(--color-info)]', count_bg: 'bg-[rgba(91,141,239,0.2)]' },
    { key: 'review', label: 'Review', dot: 'bg-[var(--color-warning)]', count_bg: 'bg-[rgba(251,191,36,0.2)]' },
    { key: 'done', label: 'Done', dot: 'bg-[var(--color-success)]', count_bg: 'bg-[rgba(52,211,153,0.2)]' },
];

const priorityColor: Record<string, string> = {
    low: 'bg-[var(--color-priority-low)]', medium: 'bg-[var(--color-priority-medium)]',
    high: 'bg-[var(--color-priority-high)]', critical: 'bg-[var(--color-priority-critical)]',
};

const Tasks = () => {
    const [tasks, setTasks] = useState<Task[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchTasks = async () => {
        try { const { data } = await api.get('/tasks'); setTasks(data); }
        catch (e) { console.error(e); }
        finally { setLoading(false); }
    };
    useEffect(() => { fetchTasks(); }, []);

    const updateStatus = async (taskId: string, status: string) => {
        try { await api.patch(`/tasks/${taskId}/status`, { status }); fetchTasks(); }
        catch (e) { console.error(e); }
    };

    if (loading) return <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-[var(--color-border)] border-t-[var(--color-accent)] rounded-full animate-[spin_0.8s_linear_infinite]" /></div>;

    return (
        <div className="p-8 max-w-[1400px] animate-[fade-in_0.3s_ease]">
            <div className="flex justify-between items-center mb-8">
                <h1 className="text-[28px] font-extrabold tracking-tight accent-gradient-text">Tasks Board</h1>
                <p className="text-sm text-[var(--color-text-secondary)]">{tasks.length} total tasks</p>
            </div>

            {tasks.length === 0 ? (
                <div className="text-center py-12 text-[var(--color-text-muted)]">
                    <div className="text-5xl mb-3 opacity-50">📋</div>
                    <h3 className="text-[var(--color-text-secondary)] text-lg mb-1">No tasks yet</h3>
                    <p>Create tasks from within your projects</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
                    {statusCols.map((col) => {
                        const colTasks = tasks.filter(t => t.status === col.key);
                        return (
                            <div key={col.key} className="bg-[var(--color-bg-secondary)] rounded-2xl p-4 border border-[var(--color-border)]">
                                <div className="flex items-center gap-2 mb-4">
                                    <div className={`w-2.5 h-2.5 rounded-full ${col.dot}`} />
                                    <h3 className="text-sm font-bold text-[var(--color-text-secondary)]">{col.label}</h3>
                                    <span className={`ml-auto text-xs text-[var(--color-text-muted)] ${col.count_bg} px-2 py-0.5 rounded-full font-semibold`}>{colTasks.length}</span>
                                </div>
                                <div className="flex flex-col gap-2 min-h-[120px]">
                                    {colTasks.map((task) => (
                                        <div key={task._id} className="bg-[var(--color-bg-card)] border border-[var(--color-border)] rounded-xl p-3.5 hover:border-[var(--color-border-active)] transition-all">
                                            <div className="flex items-center gap-2 mb-1.5">
                                                <div className={`w-2 h-2 rounded-full shrink-0 ${priorityColor[task.priority]}`} title={task.priority} />
                                                <h4 className="text-sm font-semibold truncate">{task.title}</h4>
                                            </div>
                                            {task.project && <p className="text-[11px] text-[var(--color-text-muted)] mb-2 truncate">{task.project.title}</p>}
                                            <div className="flex items-center justify-between">
                                                <select value={task.status} onChange={(e) => updateStatus(task._id, e.target.value)}
                                                    className="text-[11px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] rounded-md px-2 py-1 text-[var(--color-text-secondary)] outline-none cursor-pointer">
                                                    {statusCols.map(s => <option key={s.key} value={s.key}>{s.label}</option>)}
                                                </select>
                                                <div className="flex items-center gap-2">
                                                    {task.dueDate && <span className="text-[10px] text-[var(--color-text-muted)]">{new Date(task.dueDate).toLocaleDateString()}</span>}
                                                    {task.assignee && (
                                                        <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-[10px] font-bold text-white" title={task.assignee.name}>
                                                            {task.assignee.name.charAt(0).toUpperCase()}
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default Tasks;
