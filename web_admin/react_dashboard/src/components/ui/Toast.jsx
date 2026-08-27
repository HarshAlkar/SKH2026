import { useEffect, useState } from 'react';

let pushToast = () => {};

export function toast(message, tone = 'ok') {
  pushToast({ id: Date.now(), message, tone });
}

export function ToastHost() {
  const [items, setItems] = useState([]);

  useEffect(() => {
    pushToast = (item) => {
      setItems((prev) => [...prev, item]);
      setTimeout(() => setItems((prev) => prev.filter((x) => x.id !== item.id)), 3200);
    };
  }, []);

  return (
    <div className="fixed bottom-4 right-4 z-[60] space-y-2">
      {items.map((item) => (
        <div
          key={item.id}
          className={`rounded-xl px-4 py-3 text-sm text-white shadow-lg ${
            item.tone === 'error' ? 'bg-rose-600' : 'bg-slate-900'
          }`}
        >
          {item.message}
        </div>
      ))}
    </div>
  );
}
