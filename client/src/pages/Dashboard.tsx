import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { HiOutlineFolder, HiOutlineClipboardList, HiOutlineCheck, HiOutlineClock } from 'react-icons/hi';
import api from '../services/api';

interface Project {
    _id: string; title: string; status: string; priority: string; deadline: string | null; createdAt: string;
}
interface Task {
    _id: string; title: string; status: string; priority: string; project?: { title: string };
}

const badgeColor: Record<string, string> = {
    active: 'bg-[rgba(91,141,239,0.15)] text-[var(--color-info)]',
    completed: 'bg-[rgba(52,211,153,0.15)] text-[var(--color-success)]',
    'on-hold': 'bg-[rgba(251,191,36,0.15)] text-[var(--color-warning)]',
    todo: 'bg-[rgba(106,106,138,0.15)] text-[var(--color-text-muted)]',
    'in-progress': 'bg-[rgba(91,141,239,0.15)] text-[var(--color-info)]',
    review: 'bg-[rgba(251,191,36,0.15)] text-[var(--color-warning)]',
    done: 'bg-[rgba(52,211,153,0.15)] text-[var(--color-success)]',
    low: 'bg-[rgba(52,211,153,0.15)] text-[var(--color-priority-low)]',
    medium: 'bg-[rgba(251,191,36,0.15)] text-[var(--color-priority-medium)]',
    high: 'bg-[rgba(251,146,60,0.15)] text-[var(--color-priority-high)]',
    critical: 'bg-[rgba(248,113,113,0.15)] text-[var(--color-priority-critical)]',
};

const Badge = ({ value }: { value: string }) => (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold uppercase tracking-wider ${badgeColor[value] || ''}`}>
        {value.replace('-', ' ')}
    </span>
);

const Dashboard = () => {
    const { user } = useAuth();
    const [projects, setProjects] = useState<Project[]>([]);
    const [tasks, setTasks] = useState<Task[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const [p, t] = await Promise.all([api.get('/projects'), api.get('/tasks')]);
                setProjects(p.data);
                setTasks(t.data);
            } catch (e) { console.error(e); }
            finally { setLoading(false); }
        };
        fetchData();
    }, []);

    const stats = [
        { label: 'Total Projects', value: projects.length, icon: <HiOutlineFolder />, color: 'var(--color-accent)', bg: 'rgba(124,92,252,0.12)' },
        { label: 'Total Tasks', value: tasks.length, icon: <HiOutlineClipboardList />, color: 'var(--color-accent-secondary)', bg: 'rgba(91,141,239,0.12)' },
        { label: 'Completed', value: tasks.filter(t => t.status === 'done').length, icon: <HiOutlineCheck />, color: 'var(--color-success)', bg: 'rgba(52,211,153,0.12)' },
        { label: 'In Progress', value: tasks.filter(t => t.status === 'in-progress').length, icon: <HiOutlineClock />, color: 'var(--color-warning)', bg: 'rgba(251,191,36,0.12)' },
    ];

    if (loading) return <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-[var(--color-border)] border-t-[var(--color-accent)] rounded-full animate-[spin_0.8s_linear_infinite]" /></div>;

    return (
        <div className="p-8 max-w-[1400px] animate-[fade-in_0.3s_ease]">
            <div className="mb-8">
                <h1 className="text-[32px] font-extrabold tracking-tight mb-1">Welcome back, {user?.name?.split(' ')[0]} 👋</h1>
                <p className="text-[var(--color-text-secondary)] text-[15px]">Here's what's happening with your projects today.</p>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-8">
                {stats.map((s) => (
                    <div key={s.label} className="card-base flex items-center gap-4 hover:card-base-hover hover:-translate-y-0.5 hover:shadow-[0_4px_16px_rgba(0,0,0,0.3)]">
                        <div className="w-12 h-12 rounded-[10px] flex items-center justify-center text-[22px]" style={{ background: s.bg, color: s.color }}>{s.icon}</div>
                        <div>
                            <h3 className="text-[28px] font-bold tracking-tight">{s.value}</h3>
                            <p className="text-[13px] text-[var(--color-text-secondary)] font-medium">{s.label}</p>
                        </div>
                    </div>
                ))}
            </div>

            {/* Sections */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Recent Projects */}
                <div className="card-base">
                    <h2 className="text-lg font-bold mb-4">Recent Projects</h2>
                    {projects.length === 0 ? (
                        <div className="text-center py-8 text-[var(--color-text-muted)]">
                            <div className="text-5xl mb-3 opacity-50">📁</div>
                            <h3 className="text-[var(--color-text-secondary)] text-lg mb-1">No projects yet</h3>
                            <p>Create your first project to get started</p>
                        </div>
                    ) : (
                        <div className="flex flex-col gap-0.5">
                            {projects.slice(0, 5).map((p) => (
                                <div key={p._id} className="flex justify-between items-center p-3 rounded-[10px] hover:bg-[var(--color-bg-glass-hover)] transition-colors duration-150">
                                    <div><h4 className="text-sm font-semibold mb-0.5">{p.title}</h4><Badge value={p.status} /></div>
                                    <Badge value={p.priority} />
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Recent Tasks */}
                <div className="card-base">
                    <h2 className="text-lg font-bold mb-4">Recent Tasks</h2>
                    {tasks.length === 0 ? (
                        <div className="text-center py-8 text-[var(--color-text-muted)]">
                            <div className="text-5xl mb-3 opacity-50">📋</div>
                            <h3 className="text-[var(--color-text-secondary)] text-lg mb-1">No tasks yet</h3>
                            <p>Create tasks within your projects</p>
                        </div>
                    ) : (
                        <div className="flex flex-col gap-0.5">
                            {tasks.slice(0, 5).map((t) => (
                                <div key={t._id} className="flex justify-between items-center p-3 rounded-[10px] hover:bg-[var(--color-bg-glass-hover)] transition-colors duration-150">
                                    <div><h4 className="text-sm font-semibold mb-0.5">{t.title}</h4><span className="text-xs text-[var(--color-text-muted)]">{t.project?.title || 'No project'}</span></div>
                                    <Badge value={t.status} />
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
