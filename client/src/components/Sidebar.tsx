import { NavLink, useLocation } from 'react-router-dom';
import {
    HiOutlineViewGrid,
    HiOutlineFolder,
    HiOutlineClipboardList,
    HiOutlineUsers,
    HiOutlineCog,
    HiOutlineChevronLeft,
    HiOutlineChevronRight,
    HiOutlineLightningBolt
} from 'react-icons/hi';

interface SidebarProps {
    collapsed: boolean;
    onToggle: () => void;
}

const navItems = [
    { to: '/', icon: HiOutlineViewGrid, label: 'Dashboard' },
    { to: '/projects', icon: HiOutlineFolder, label: 'Projects' },
    { to: '/tasks', icon: HiOutlineClipboardList, label: 'Tasks' },
    { to: '/team', icon: HiOutlineUsers, label: 'Team' },
    { to: '/settings', icon: HiOutlineCog, label: 'Settings' },
];

const Sidebar = ({ collapsed, onToggle }: SidebarProps) => {
    const location = useLocation();

    return (
        <aside
            className={`fixed left-0 top-0 bottom-0 bg-[var(--color-bg-secondary)] border-r border-[var(--color-border)] flex flex-col p-4 z-50 overflow-hidden transition-all duration-250 ease-in-out ${collapsed ? 'w-[72px]' : 'w-[260px]'
                }`}
        >
            {/* Brand */}
            <div className="flex items-center gap-4 p-4 mb-8">
                <div className="w-10 h-10 rounded-[10px] bg-gradient-to-br from-[#7c5cfc] to-[#5b8def] flex items-center justify-center text-xl text-white shrink-0">
                    <HiOutlineLightningBolt />
                </div>
                {!collapsed && (
                    <span className="text-xl font-extrabold tracking-tight accent-gradient-text whitespace-nowrap">
                        ProManager
                    </span>
                )}
            </div>

            {/* Nav */}
            <nav className="flex-1 flex flex-col gap-1">
                {navItems.map(({ to, icon: Icon, label }) => {
                    const isActive = location.pathname === to;
                    return (
                        <NavLink
                            key={to}
                            to={to}
                            title={collapsed ? label : undefined}
                            className={`flex items-center gap-4 px-3.5 py-2.5 rounded-[10px] text-sm font-medium transition-all duration-150 no-underline relative ${isActive
                                    ? 'bg-[rgba(124,92,252,0.12)] text-[var(--color-accent)]'
                                    : 'text-[var(--color-text-secondary)] hover:bg-[var(--color-bg-glass-hover)] hover:text-[var(--color-text-primary)]'
                                }`}
                        >
                            <Icon className="text-xl shrink-0" />
                            {!collapsed && <span>{label}</span>}
                            {!collapsed && isActive && (
                                <div className="absolute -right-4 top-1/2 -translate-y-1/2 w-[3px] h-6 bg-gradient-to-b from-[#7c5cfc] to-[#5b8def] rounded-full" />
                            )}
                        </NavLink>
                    );
                })}
            </nav>

            {/* Toggle */}
            <button
                onClick={onToggle}
                className="flex items-center justify-center w-full p-2 rounded-[10px] bg-[var(--color-bg-glass)] border border-[var(--color-border)] text-[var(--color-text-secondary)] text-lg cursor-pointer transition-all duration-150 hover:bg-[var(--color-bg-glass-hover)] hover:text-[var(--color-text-primary)]"
            >
                {collapsed ? <HiOutlineChevronRight /> : <HiOutlineChevronLeft />}
            </button>
        </aside>
    );
};

export default Sidebar;
