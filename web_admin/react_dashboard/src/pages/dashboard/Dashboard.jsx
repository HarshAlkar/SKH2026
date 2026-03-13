import React from 'react';
import { Users, Stethoscope, Clock, AlertCircle } from 'lucide-react';

const Card = ({ title, value, subValue, icon, color }) => (
  <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100 flex items-start justify-between">
    <div>
      <p className="text-slate-500 text-sm font-medium">{title}</p>
      <h3 className="text-2xl font-bold mt-1">{value}</h3>
      <p className="text-xs text-slate-400 mt-1">{subValue}</p>
    </div>
    <div className={`p-3 rounded-lg ${color} text-white`}>
      {icon}
    </div>
  </div>
);

const Dashboard = () => {
  return (
    <div className="p-8">
      <header className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900">Health Overview</h1>
        <p className="text-slate-500">Welcome back, Admin. Here's what's happening today.</p>
      </header>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <Card 
          title="Total Patients" 
          value="1,284" 
          subValue="+12% from last month" 
          icon={<Users size={24} />} 
          color="bg-blue-500"
        />
        <Card 
          title="Active Doctors" 
          value="48" 
          subValue="4 currently online" 
          icon={<Stethoscope size={24} />} 
          color="bg-emerald-500"
        />
        <Card 
          title="Pending Consultations" 
          value="12" 
          subValue="3 high priority" 
          icon={<Clock size={24} />} 
          color="bg-amber-500"
        />
        <Card 
          title="Emergency Alerts" 
          value="2" 
          subValue="Last 24 hours" 
          icon={<AlertCircle size={24} />} 
          color="bg-rose-500"
        />
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <h2 className="text-lg font-bold mb-4">Recent Consultations</h2>
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="flex items-center justify-between p-3 hover:bg-slate-50 rounded-lg transition-colors cursor-pointer">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-slate-200" />
                  <div>
                    <p className="font-medium">Patient #{1024 + i}</p>
                    <p className="text-xs text-slate-500">Symptom check: Viral Fever</p>
                  </div>
                </div>
                <span className="text-xs font-medium px-2 py-1 bg-blue-100 text-blue-700 rounded-full">Completed</span>
              </div>
            ))}
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <h2 className="text-lg font-bold mb-4">ASHA Worker Activity</h2>
          <div className="space-y-4">
             {['Anita', 'Sunita', 'Priya'].map((name, i) => (
              <div key={i} className="flex items-center justify-between p-3 hover:bg-slate-50 rounded-lg transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-500">
                    {name[0]}
                  </div>
                  <div>
                    <p className="font-medium">{name}</p>
                    <p className="text-xs text-slate-500">Region: Rural Sector {i + 1}</p>
                  </div>
                </div>
                <p className="text-xs font-medium">{4 + i} visits today</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
