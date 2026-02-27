import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { HiOutlinePlus, HiOutlineTrash, HiOutlineCalendar } from 'react-icons/hi';
import api from '../services/api';

interface Project {
    _id: string; title: string; description: string; status: string; priority: string;
    owner: { name: string; email: string }; members: { _id: string; name: string }[];
    deadline: string | null; createdAt: string;
}

const badgeColor: Record<string, string> = {
    active: 'bg-[rgba(91,141,239,0.15)] text-[var(--color-info)]',
    completed: 'bg-[rgba(52,211,153,0.15)] text-[var(--color-success)]',
    'on-hold': 'bg-[rgba(251,191,36,0.15)] text-[var(--color-warning)]',
    low: 'bg-[rgba(52,211,153,0.15)] text-[var(--color-priority-low)]',
    medium: 'bg-[rgba(251,191,36,0.15)] text-[var(--color-priority-medium)]',
    high: 'bg-[rgba(251,146,60,0.15)] text-[var(--color-priority-high)]',
    critical: 'bg-[rgba(248,113,113,0.15)] text-[var(--color-priority-critical)]',
};

const Projects = () => {
    const [projects, setProjects] = useState<Project[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [formData, setFormData] = useState({ title: '', description: '', status: 'active', priority: 'medium', deadline: '' });
    const navigate = useNavigate();

    const fetchProjects = async () => {
        try { const { data } = await api.get('/projects'); setProjects(data); }
        catch (e) { console.error(e); }
        finally { setLoading(false); }
    };
    useEffect(() => { fetchProjects(); }, []);

    const handleCreate = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            await api.post('/projects', { ...formData, deadline: formData.deadline || null });
            setShowModal(false);
            setFormData({ title: '', description: '', status: 'active', priority: 'medium', deadline: '' });
            fetchProjects();
        } catch (e) { console.error(e); }
    };

    const handleDelete = async (id: string, e: React.MouseEvent) => {
        e.stopPropagation();
        if (!window.confirm('Delete this project and all its tasks?')) return;
        try { await api.delete(`/projects/${id}`); fetchProjects(); } catch (e) { console.error(e); }
    };

    if (loading) return <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-[var(--color-border)] border-t-[var(--color-accent)] rounded-full animate-[spin_0.8s_linear_infinite]" /></div>;

    const inputCls = "w-full input-base focus:input-focus";
    const selectCls = "w-full input-base focus:input-focus appearance-none bg-[length:12px] bg-[url('data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2212%22%20height%3D%2212%22%20fill%3D%22%23a0a0c0%22%20viewBox%3D%220%200%2016%2016%22%3E%3Cpath%20d%3D%22M8%2011L3%206h10l-5%205z%22%2F%3E%3C%2Fsvg%3E')] bg-no-repeat bg-[right_12px_center] pr-9";

    return (
        <div className="p-8 max-w-[1400px] animate-[fade-in_0.3s_ease]">
            <div className="flex justify-between items-center mb-8">
                <h1 className="text-[28px] font-extrabold tracking-tight accent-gradient-text">Projects</h1>
                <button onClick={() => setShowModal(true)} className="inline-flex items-center gap-2 px-5 py-2.5 rounded-[10px] text-sm font-semibold btn-primary hover:btn-primary-hover transition-all duration-250 cursor-pointer border-none">
                    <HiOutlinePlus /> New Project
                </button>
            </div>

            {projects.length === 0 ? (
                <div className="text-center py-12 text-[var(--color-text-muted)]">
                    <div className="text-5xl mb-3 opacity-50">📁</div>
                    <h3 className="text-[var(--color-text-secondary)] text-lg mb-1">No projects yet</h3>
                    <p>Create your first project to start managing tasks</p>
                    <button onClick={() => setShowModal(true)} className="mt-4 inline-flex items-center gap-2 px-5 py-2.5 rounded-[10px] text-sm font-semibold btn-primary hover:btn-primary-hover transition-all duration-250 cursor-pointer border-none">
                        <HiOutlinePlus /> Create Project
                    </button>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                    {projects.map((p) => (
                        <div key={p._id} onClick={() => navigate(`/projects/${p._id}`)}
                            className="card-base flex flex-col gap-2 cursor-pointer hover:card-base-hover transition-all duration-250">
                            <div className="flex justify-between items-center">
                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold uppercase tracking-wider ${badgeColor[p.status]}`}>{p.status}</span>
                                <button onClick={(e) => handleDelete(p._id, e)} className="w-8 h-8 flex items-center justify-center rounded-[10px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] text-[var(--color-text-secondary)] cursor-pointer hover:bg-[var(--color-bg-glass-hover)] hover:text-[var(--color-text-primary)] transition-all text-sm">
                                    <HiOutlineTrash />
                                </button>
                            </div>
                            <h3 className="text-[17px] font-bold tracking-tight">{p.title}</h3>
                            <p className="text-[13px] text-[var(--color-text-secondary)] line-clamp-2">{p.description || 'No description'}</p>
                            <div className="flex items-center gap-2 mt-1">
                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold uppercase tracking-wider ${badgeColor[p.priority]}`}>{p.priority}</span>
                                {p.deadline && <span className="flex items-center gap-1 text-xs text-[var(--color-text-muted)]"><HiOutlineCalendar /> {new Date(p.deadline).toLocaleDateString()}</span>}
                            </div>
                            <div className="flex items-center mt-auto pt-2 border-t border-[var(--color-border)]">
                                <div className="w-7 h-7 rounded-full bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-[11px] font-bold text-white shrink-0" title={p.owner.name}>
                                    {p.owner.name.charAt(0).toUpperCase()}
                                </div>
                                {p.members.slice(0, 3).map((m) => (
                                    <div key={m._id} className="w-7 h-7 rounded-full bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-[11px] font-bold text-white shrink-0 -ml-2" title={m.name}>
                                        {m.name.charAt(0).toUpperCase()}
                                    </div>
                                ))}
                                {p.members.length > 3 && <span className="text-[11px] text-[var(--color-text-muted)] ml-1">+{p.members.length - 3}</span>}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Create Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/60 backdrop-blur-[4px] flex items-center justify-center z-[1000] animate-[fade-in_0.2s_ease]" onClick={() => setShowModal(false)}>
                    <div className="bg-[var(--color-bg-secondary)] border border-[var(--color-border)] rounded-[20px] p-8 w-[90%] max-w-[520px] animate-[slide-up_0.3s_ease]" onClick={(e) => e.stopPropagation()}>
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-xl font-bold">New Project</h2>
                            <button onClick={() => setShowModal(false)} className="w-9 h-9 flex items-center justify-center rounded-[10px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] text-[var(--color-text-secondary)] cursor-pointer hover:bg-[var(--color-bg-glass-hover)]">✕</button>
                        </div>
                        <form onSubmit={handleCreate} className="flex flex-col gap-4">
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Title</label>
                                <input className={inputCls} placeholder="Project title" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} required />
                            </div>
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Description</label>
                                <textarea className={`${inputCls} min-h-[80px] resize-y`} placeholder="Brief description..." value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} />
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div className="flex flex-col gap-1.5">
                                    <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Status</label>
                                    <select className={selectCls} value={formData.status} onChange={(e) => setFormData({ ...formData, status: e.target.value })}>
                                        <option value="active">Active</option>
                                        <option value="on-hold">On Hold</option>
                                        <option value="completed">Completed</option>
                                    </select>
                                </div>
                                <div className="flex flex-col gap-1.5">
                                    <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Priority</label>
                                    <select className={selectCls} value={formData.priority} onChange={(e) => setFormData({ ...formData, priority: e.target.value })}>
                                        <option value="low">Low</option>
                                        <option value="medium">Medium</option>
                                        <option value="high">High</option>
                                        <option value="critical">Critical</option>
                                    </select>
                                </div>
                            </div>
                            <div className="flex flex-col gap-1.5">
                                <label className="text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider">Deadline</label>
                                <input type="date" className={inputCls} value={formData.deadline} onChange={(e) => setFormData({ ...formData, deadline: e.target.value })} />
                            </div>
                            <div className="flex justify-end gap-2 mt-4">
                                <button type="button" onClick={() => setShowModal(false)} className="px-5 py-2.5 rounded-[10px] text-sm font-semibold bg-[var(--color-bg-glass)] text-[var(--color-text-primary)] border border-[var(--color-border)] cursor-pointer hover:bg-[var(--color-bg-glass-hover)]">Cancel</button>
                                <button type="submit" className="px-5 py-2.5 rounded-[10px] text-sm font-semibold btn-primary hover:btn-primary-hover transition-all duration-250 cursor-pointer border-none">Create Project</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Projects;
