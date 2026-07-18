export function HealthBadge({ value }) {
  const v = Number(value);
  const color =
    v >= 90
      ? 'bg-green-100/70 text-green-700'
      : v >= 70
      ? 'bg-orange-100/70 text-orange-700'
      : 'bg-red-100/70 text-red-700';
  return (
    <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${color}`}>{v}%</span>
  );
}

export function StatusBadge({ active }) {
  return active ? (
    <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-green-100/70 text-green-700">
      Aktif
    </span>
  ) : (
    <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-200/70 text-gray-600">
      Non-aktif
    </span>
  );
}

export function Card({ children, className = '' }) {
  return <div className={`glass ${className}`}>{children}</div>;
}

export function Button({
  children,
  onClick,
  type = 'button',
  variant = 'primary',
  disabled,
  className = '',
}) {
  const base =
    'inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition disabled:opacity-50 disabled:cursor-not-allowed';
  const variants = {
    primary:
      'bg-gradient-to-r from-brand to-indigo-500 text-white shadow-lg shadow-brand/20 hover:from-brand-dark hover:to-indigo-600',
    danger:
      'bg-gradient-to-r from-red-500 to-red-600 text-white shadow-lg shadow-red-500/20 hover:from-red-600',
    ghost: 'bg-white/50 text-navy hover:bg-white/70 backdrop-blur',
    outline: 'border border-white/60 bg-white/30 text-navy hover:bg-white/50 backdrop-blur',
  };
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`${base} ${variants[variant]} ${className}`}
    >
      {children}
    </button>
  );
}
