import { useState, useEffect } from 'react';
import { HiOutlineMail } from 'react-icons/hi';
import api from '../services/api';

interface User {
    _id: string; name: string; email: string; role: string; createdAt: string;
}

const roleColor: Record<string, string> = {
    admin: 'bg-[rgba(248,113,113,0.15)] text-[var(--color-danger)]',
    manager: 'bg-[rgba(251,191,36,0.15)] text-[var(--color-warning)]',
    member: 'bg-[rgba(91,141,239,0.15)] text-[var(--color-info)]',
};

const Team = () => {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchUsers = async () => {
            try { const { data } = await api.get('/users'); setUsers(data); }
            catch (e) { console.error(e); }
            finally { setLoading(false); }
        };
        fetchUsers();
    }, []);

    if (loading) return <div className="flex items-center justify-center min-h-[200px]"><div className="w-8 h-8 border-3 border-[var(--color-border)] border-t-[var(--color-accent)] rounded-full animate-[spin_0.8s_linear_infinite]" /></div>;

    return (
        <div className="p-8 max-w-[1400px] animate-[fade-in_0.3s_ease]">
            <div className="flex justify-between items-center mb-8">
                <h1 className="text-[28px] font-extrabold tracking-tight accent-gradient-text">Team</h1>
                <p className="text-sm text-[var(--color-text-secondary)]">{users.length} members</p>
            </div>

            {users.length === 0 ? (
                <div className="text-center py-12 text-[var(--color-text-muted)]">
                    <div className="text-5xl mb-3 opacity-50">👥</div>
                    <h3 className="text-[var(--color-text-secondary)] text-lg mb-1">No team members</h3>
                    <p>Members will appear here once they register</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
                    {users.map((u) => (
                        <div key={u._id} className="card-base flex items-center gap-4 hover:card-base-hover transition-all">
                            <div className="w-14 h-14 rounded-full bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-[22px] font-bold text-white shrink-0">
                                {u.name.charAt(0).toUpperCase()}
                            </div>
                            <div className="flex-1 min-w-0">
                                <h3 className="text-base font-bold truncate">{u.name}</h3>
                                <div className="flex items-center gap-1.5 text-[13px] text-[var(--color-text-muted)] truncate">
                                    <HiOutlineMail className="shrink-0" />
                                    <span className="truncate">{u.email}</span>
                                </div>
                                <span className={`mt-1.5 inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold uppercase tracking-wider ${roleColor[u.role] || ''}`}>
                                    {u.role}
                                </span>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default Team;
