import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import Sidebar from './components/sidebar/Sidebar';
import AppRoutes from './routes/AppRoutes';
import './App.css';

function App() {
  return (
    <Router>
      <div className="flex bg-slate-50 min-h-screen">
        <Sidebar />
        <main className="flex-1 overflow-auto">
          <AppRoutes />
        </main>
      </div>
    </Router>
  );
}

export default App;
