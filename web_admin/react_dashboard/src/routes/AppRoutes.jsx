import React from 'react';
import { Routes, Route } from 'react-router-dom';
import Dashboard from '../pages/dashboard/Dashboard';

// Placeholder for other pages
const Placeholder = ({ title }) => (
  <div className="p-8">
    <h1 className="text-2xl font-bold">{title}</h1>
    <p className="mt-4 text-slate-500">This module is part of the full-stack extension.</p>
  </div>
);

const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<Dashboard />} />
      <Route path="/users" element={<Placeholder title="Patient Management" />} />
      <Route path="/doctors" element={<Placeholder title="Doctor Management" />} />
      <Route path="/asha-workers" element={<Placeholder title="ASHA Worker Management" />} />
      <Route path="/consultations" element={<Placeholder title="Consultation History" />} />
      <Route path="/prescriptions" element={<Placeholder title="Prescription Records" />} />
      <Route path="/reports" element={<Placeholder title="Health Analytics & Reports" />} />
    </Routes>
  );
};

export default AppRoutes;
