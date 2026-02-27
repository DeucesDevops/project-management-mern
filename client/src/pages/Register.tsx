import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { HiOutlineLightningBolt, HiOutlineMail, HiOutlineLockClosed, HiOutlineUser } from 'react-icons/hi';

const Register = () => {
    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { register } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        if (password !== confirmPassword) { setError('Passwords do not match'); return; }
        setLoading(true);
        try {
            await register(name, email, password);
            navigate('/');
        } catch (err: any) {
            setError(err.response?.data?.message || 'Registration failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const inputClass = "w-full input-base pl-10 focus:input-focus";
    const labelClass = "text-[13px] font-medium text-[var(--color-text-secondary)] uppercase tracking-wider";

    return (
        <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-[var(--color-bg-primary)]">
            <div className="absolute inset-0 overflow-hidden pointer-events-none">
                <div className="absolute w-[400px] h-[400px] rounded-full bg-[var(--color-accent)] opacity-40 blur-[80px] -top-[100px] -right-[100px] animate-[float-orb_8s_ease-in-out_infinite]" />
                <div className="absolute w-[300px] h-[300px] rounded-full bg-[var(--color-accent-secondary)] opacity-40 blur-[80px] -bottom-[80px] -left-[80px] animate-[float-orb_10s_ease-in-out_infinite_reverse]" />
                <div className="absolute w-[200px] h-[200px] rounded-full bg-purple-500 opacity-40 blur-[80px] top-1/2 left-1/2 animate-[float-orb_12s_ease-in-out_infinite]" />
            </div>

            <div className="glass-card w-full max-w-[440px] mx-4 relative z-10 animate-[slide-up_0.5s_ease]">
                <div className="text-center mb-8">
                    <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-[28px] text-white mx-auto mb-4 shadow-[0_0_20px_var(--color-accent-glow)]">
                        <HiOutlineLightningBolt />
                    </div>
                    <h1 className="text-[26px] font-extrabold tracking-tight mb-1">Create Account</h1>
                    <p className="text-[var(--color-text-secondary)] text-sm">Get started with ProManager today</p>
                </div>

                {error && (
                    <div className="bg-[rgba(248,113,113,0.1)] border border-[rgba(248,113,113,0.3)] text-[var(--color-danger)] px-4 py-2.5 rounded-[10px] text-[13px] mb-4 text-center">
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                    <div className="flex flex-col gap-1.5">
                        <label className={labelClass}>Full Name</label>
                        <div className="relative">
                            <HiOutlineUser className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                            <input type="text" placeholder="John Doe" value={name} onChange={(e) => setName(e.target.value)} required className={inputClass} />
                        </div>
                    </div>
                    <div className="flex flex-col gap-1.5">
                        <label className={labelClass}>Email</label>
                        <div className="relative">
                            <HiOutlineMail className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                            <input type="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} required className={inputClass} />
                        </div>
                    </div>
                    <div className="flex flex-col gap-1.5">
                        <label className={labelClass}>Password</label>
                        <div className="relative">
                            <HiOutlineLockClosed className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                            <input type="password" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} required minLength={6} className={inputClass} />
                        </div>
                    </div>
                    <div className="flex flex-col gap-1.5">
                        <label className={labelClass}>Confirm Password</label>
                        <div className="relative">
                            <HiOutlineLockClosed className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                            <input type="password" placeholder="••••••••" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} required minLength={6} className={inputClass} />
                        </div>
                    </div>

                    <button type="submit" disabled={loading}
                        className="w-full flex items-center justify-center gap-2 py-3.5 rounded-[10px] text-[15px] font-semibold cursor-pointer btn-primary hover:btn-primary-hover transition-all duration-250 mt-2 disabled:opacity-50 border-none">
                        {loading ? <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-[spin_0.8s_linear_infinite]" /> : 'Create Account'}
                    </button>
                </form>

                <p className="text-center mt-6 text-sm text-[var(--color-text-secondary)]">
                    Already have an account? <Link to="/login" className="font-semibold text-[var(--color-accent)] hover:underline no-underline">Sign in</Link>
                </p>
            </div>
        </div>
    );
};

export default Register;
