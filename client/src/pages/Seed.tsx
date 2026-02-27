import { useState } from 'react';
import api from '../services/api';
import { HiOutlineDatabase, HiOutlineCheckCircle, HiOutlineXCircle, HiOutlineRefresh } from 'react-icons/hi';

const Seed = () => {
    const [status, setStatus] = useState<string[]>([]);
    const [loading, setLoading] = useState(false);

    const log = (msg: string) => {
        setStatus(prev => [...prev, msg]);
    };

    const runSeed = async () => {
        setLoading(true);
        setStatus([]);
        log('🚀 Starting seeding process...');

        const firstNames = ['John', 'Jane', 'Michael', 'Emily', 'Chris', 'Sarah', 'David', 'Laura', 'Robert', 'Linda'];
        const lastNames = ['Smith', 'Doe', 'Johnson', 'Brown', 'Davis', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas'];
        const projectTitles = ['Website Redraw', 'Mobile App Beta', 'CRM Integration', 'Cloud Migration', 'AI Research', 'Marketing Site', 'Inventory System', 'API Gateway', 'Security Audit', 'Data Analytics'];

        try {
            for (let i = 0; i < 10; i++) {
                const name = `${firstNames[i]} ${lastNames[i]}`;
                const email = `${firstNames[i].toLowerCase()}.${lastNames[i].toLowerCase()}@example.com`;
                const password = 'password123';

                log(`👤 Creating user: ${name}...`);

                // Register User
                const { data: userData } = await api.post('/auth/register', { name, email, password });
                log(`✅ User ${name} created. Token: ${userData.token.substring(0, 10)}...`);

                // Set token for subsequent requests
                localStorage.setItem('token', userData.token);
                // Note: AuthContext usually handles this, but here we are in a script-like page
                // We might need to refresh the page or manually set headers if the api service doesn't pick it up automatically
                // Usually `api.interceptors` handles it if it's set in localStorage.

                // Create Projects for this user
                for (let j = 0; j < 3; j++) {
                    const projectTitle = `${projectTitles[(i * 3 + j) % projectTitles.length]} - ${firstNames[i]}`;
                    log(`📁 Creating project: ${projectTitle}...`);
                    await api.post('/projects', {
                        title: projectTitle,
                        description: `Sample project created for ${name}.`,
                        status: 'active',
                        priority: 'medium',
                        deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
                    });
                }

                log(`🎉 Projects for ${name} completed.`);
                // Clear token to be safe before next iteration (though we overwrite it)
                localStorage.removeItem('token');
            }
            log('🏆 Seeding complete! All 10 users and 30 projects created.');
        } catch (err: any) {
            log(`❌ Error: ${err.response?.data?.message || err.message}`);
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-[var(--color-bg-primary)] p-8">
            <div className="glass-card w-full max-w-[600px] animate-[slide-up_0.5s_ease]">
                <div className="text-center mb-8">
                    <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-[32px] text-white mx-auto mb-4 shadow-lg">
                        <HiOutlineDatabase />
                    </div>
                    <h1 className="text-2xl font-bold mb-2 text-[var(--color-text-primary)]">Data Seeding Tool</h1>
                    <p className="text-[var(--color-text-secondary)] text-sm">
                        This utility adds 10 sample users and projects to your database.
                    </p>
                </div>

                <div className="flex flex-col gap-4">
                    <button
                        onClick={runSeed}
                        disabled={loading}
                        className="w-full flex items-center justify-center gap-2 py-4 rounded-xl text-lg font-bold btn-primary disabled:opacity-50 transition-all shadow-md active:scale-[0.98]"
                    >
                        {loading ? (
                            <HiOutlineRefresh className="animate-spin text-2xl" />
                        ) : (
                            <>
                                <HiOutlineDatabase />
                                <span>Seed 10 Users & 30 Projects</span>
                            </>
                        )}
                    </button>

                    <div className="mt-4 bg-[var(--color-bg-secondary)] rounded-xl p-4 border border-[var(--color-border)] h-[300px] overflow-y-auto font-mono text-sm shadow-inner">
                        {status.length === 0 ? (
                            <div className="text-[var(--color-text-muted)] italic h-full flex items-center justify-center">
                                Activity logs will appear here...
                            </div>
                        ) : (
                            <div className="flex flex-col gap-1">
                                {status.map((s, idx) => (
                                    <div key={idx} className="animate-[fade-in_0.3s_ease]">
                                        {s.startsWith('✅') ? (
                                            <span className="text-green-500 flex items-center gap-2"><HiOutlineCheckCircle /> {s}</span>
                                        ) : s.startsWith('❌') ? (
                                            <span className="text-red-500 flex items-center gap-2"><HiOutlineXCircle /> {s}</span>
                                        ) : s.startsWith('👤') || s.startsWith('📁') ? (
                                            <span className="text-blue-400">{s}</span>
                                        ) : (
                                            <span className="text-[var(--color-text-primary)]">{s}</span>
                                        )}
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>

                <div className="mt-8 text-center text-xs text-[var(--color-text-muted)]">
                    <p>⚠️ Only use this in development environments.</p>
                </div>
            </div>
        </div>
    );
};

export default Seed;
