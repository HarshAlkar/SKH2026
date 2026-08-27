export default function LiveBadge({ active = true }) {
  if (!active) return null;
  return (
    <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full">
      <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
      Live updates active
    </span>
  );
}
