import { useAuth } from '../context/AuthContext';
import { HiOutlineBell, HiOutlineSearch, HiOutlineLogout } from 'react-icons/hi';

const Header = () => {
    const { user, logout } = useAuth();

    const getInitials = (name: string) =>
        name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);

    return (
        <header className="h-16 bg-[var(--color-bg-secondary)] border-b border-[var(--color-border)] flex items-center justify-between px-8 sticky top-0 z-40 backdrop-blur-[12px]">
            {/* Search */}
            <div className="relative w-80">
                <HiOutlineSearch className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] text-lg" />
                <input
                    type="text"
                    placeholder="Search projects, tasks..."
                    className="w-full py-2.5 pl-10 pr-4 rounded-[10px] border border-[var(--color-border)] bg-[var(--color-bg-glass)] text-[var(--color-text-primary)] text-sm font-[inherit] outline-none transition-all duration-150 focus:border-[var(--color-accent)] focus:shadow-[0_0_0_3px_rgba(124,92,252,0.15)] placeholder:text-[var(--color-text-muted)]"
                />
            </div>

            {/* Actions */}
            <div className="flex items-center gap-4">
                {/* Notifications */}
                <button className="relative w-9 h-9 flex items-center justify-center rounded-[10px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] text-[var(--color-text-secondary)] cursor-pointer transition-all duration-250 hover:bg-[var(--color-bg-glass-hover)] hover:text-[var(--color-text-primary)] hover:border-[var(--color-border-active)]">
                    <HiOutlineBell />
                    <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[var(--color-danger)] border-2 border-[var(--color-bg-secondary)]" />
                </button>

                {/* User */}
                <div className="flex items-center gap-2 py-1.5 px-3 rounded-[10px] bg-[var(--color-bg-glass)] border border-[var(--color-border)]">
                    <div className="w-9 h-9 rounded-full bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-sm font-bold text-white shrink-0">
                        {user ? getInitials(user.name) : '?'}
                    </div>
                    <div className="flex flex-col">
                        <span className="text-[13px] font-semibold text-[var(--color-text-primary)]">{user?.name}</span>
                        <span className="text-[11px] text-[var(--color-text-muted)] capitalize">{user?.role}</span>
                    </div>
                </div>

                {/* Logout */}
                <button
                    onClick={logout}
                    title="Logout"
                    className="w-9 h-9 flex items-center justify-center rounded-[10px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] text-[var(--color-text-secondary)] cursor-pointer transition-all duration-250 hover:bg-[var(--color-bg-glass-hover)] hover:text-[var(--color-text-primary)] hover:border-[var(--color-border-active)]"
                >
                    <HiOutlineLogout />
                </button>
            </div>
        </header>
    );
};

export default Header;
