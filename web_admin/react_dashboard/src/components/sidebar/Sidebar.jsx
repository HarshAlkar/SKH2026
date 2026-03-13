import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  BarChart3, 
  Users, 
  UserRound, 
  Stethoscope, 
  History, 
  FileText, 
  ShieldCheck,
  LayoutDashboard
} from 'lucide-react';

const Sidebar = () => {
  const location = useLocation();
  
  const menuItems = [
    { title: 'Dashboard', icon: <LayoutDashboard size={20} />, path: '/' },
    { title: 'Patients', icon: <Users size={20} />, path: '/users' },
    { title: 'Doctors', icon: <Stethoscope size={20} />, path: '/doctors' },
    { title: 'ASHA Workers', icon: <UserRound size={20} />, path: '/asha-workers' },
    { title: 'Consultations', icon: <History size={20} />, path: '/consultations' },
    { title: 'Prescriptions', icon: <FileText size={20} />, path: '/prescriptions' },
    { title: 'Reports', icon: <BarChart3 size={20} />, path: '/reports' },
  ];

  return (
    <div className="w-64 bg-slate-900 h-screen text-white flex flex-col">
      <div className="p-6 flex items-center gap-3 border-b border-slate-800">
        <ShieldCheck className="text-blue-400" size={32} />
        <span className="text-xl font-bold">HealthAdmin</span>
      </div>
      
      <nav className="flex-1 mt-6 px-4 space-y-2">
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link 
              key={item.title}
              to={item.path}
              className={`flex items-center gap-3 p-3 rounded-lg transition-colors ${
                isActive 
                  ? 'bg-blue-600 text-white' 
                  : 'text-slate-400 hover:bg-slate-800 hover:text-white'
              }`}
            >
              {item.icon}
              <span className="font-medium">{item.title}</span>
            </Link>
          );
        })}
      </nav>
      
      <div className="p-4 border-t border-slate-800">
        <div className="flex items-center gap-3 p-3 text-slate-400">
          <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold">
            A
          </div>
          <div>
            <p className="text-sm font-medium text-white">Admin User</p>
            <p className="text-xs">admin@hs053.com</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Sidebar;
