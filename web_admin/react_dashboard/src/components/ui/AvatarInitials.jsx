const colors = ['bg-primary', 'bg-secondary', 'bg-accent', 'bg-violet-500', 'bg-rose-500'];

export default function AvatarInitials({ name, size = 'md' }) {
  const initial = (name || '?').charAt(0).toUpperCase();
  const idx = (name || '').charCodeAt(0) % colors.length;
  const dim = size === 'sm' ? 'w-8 h-8 text-xs' : 'w-10 h-10 text-sm';
  return (
    <div className={`${dim} rounded-full ${colors[idx]} text-white flex items-center justify-center font-bold shrink-0`}>
      {initial}
    </div>
  );
}
