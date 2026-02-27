import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { HiOutlineUser, HiOutlineMail, HiOutlineLockClosed, HiOutlineCheck } from 'react-icons/hi';

const Settings = () => {
    const { user, updateProfile } = useAuth();
    const [name, setName] = useState(user?.name || '');
    const [email, setEmail] = useState(user?.email || '');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState('');
    const [error, setError] = useState('');

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setSuccess('');
        if (password && password !== confirmPassword) { setError('Passwords do not match'); return; }
        setLoading(true);
        try {
            const data: Record<string, string> = { name, email };
            if (password) data.password = password;
            await updateProfile(data);
            setSuccess('Profile updated successfully!');
            setPassword('');
            setConfirmPassword('');
        } catch (err: any) {
            setError(err.response?.data?.message || 'Failed to update profile');
        } finally {
            setLoading(false);
        }
    };

    const inputCls = "w-full input-base pl-10 focus:input-focus";
    const labelCls = "text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider";

    return (
        <div className="p-8 max-w-[600px] animate-[fade-in_0.3s_ease]">
            <h1 className="text-[28px] font-extrabold tracking-tight accent-gradient-text mb-8">Settings</h1>

            <div className="card-base">
                <div className="flex items-center gap-4 mb-6 pb-6 border-b border-[var(--color-border)]">
                    <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-2xl font-bold text-white">
                        {user?.name?.charAt(0).toUpperCase() || '?'}
                    </div>
                    <div>
                        <h2 className="text-xl font-bold">{user?.name}</h2>
                        <p className="text-sm text-[var(--color-text-muted)]">{user?.email}</p>
                    </div>
                </div>

                {success && (
                    <div className="flex items-center gap-2 bg-[rgba(52,211,153,0.1)] border border-[rgba(52,211,153,0.3)] text-[var(--color-success)] px-4 py-2.5 rounded-[10px] text-[13px] mb-4">
                        <HiOutlineCheck /> {success}
                    </div>
                )}
                {error && (
                    <div className="bg-[rgba(248,113,113,0.1)] border border-[rgba(248,113,113,0.3)] text-[var(--color-danger)] px-4 py-2.5 rounded-[10px] text-[13px] mb-4">
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                    <div className="flex flex-col gap-1.5">
                        <label className={labelCls}>Name</label>
                        <div className="relative">
                            <HiOutlineUser className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                            <input type="text" value={name} onChange={(e) => setName(e.target.value)} required className={inputCls} />
                        </div>
                    </div>
                    <div className="flex flex-col gap-1.5">
                        <label className={labelCls}>Email</label>
                        <div className="relative">
                            <HiOutlineMail className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required className={inputCls} />
                        </div>
                    </div>
                    <div className="flex flex-col gap-1.5">
                        <label className={labelCls}>New Password <span className="normal-case font-normal">(leave blank to keep current)</span></label>
                        <div className="relative">
                            <HiOutlineLockClosed className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                            <input type="password" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} className={inputCls} />
                        </div>
                    </div>
                    {password && (
                        <div className="flex flex-col gap-1.5">
                            <label className={labelCls}>Confirm Password</label>
                            <div className="relative">
                                <HiOutlineLockClosed className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                                <input type="password" placeholder="••••••••" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} className={inputCls} />
                            </div>
                        </div>
                    )}
                    <button type="submit" disabled={loading}
                        className="w-full flex items-center justify-center gap-2 py-3 rounded-[10px] text-[15px] font-semibold btn-primary hover:btn-primary-hover transition-all cursor-pointer mt-2 disabled:opacity-50 border-none">
                        {loading ? <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-[spin_0.8s_linear_infinite]" /> : 'Save Changes'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default Settings;
