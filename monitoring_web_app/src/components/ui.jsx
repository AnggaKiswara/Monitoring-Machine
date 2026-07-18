export function HealthBadge({ value }) {
  const v = Number(value);
  const color =
    v >= 90 ? 'bg-green-100 text-green-700' : v >= 70 ? 'bg-orange-100 text-orange-700' : 'bg-red-100 text-red-700';
  return (
    <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${color}`}>{v}%</span>
  );
}

export function StatusBadge({ active }) {
  return active ? (
    <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-700">
      Aktif
    </span>
  ) : (
    <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-200 text-gray-600">
      Non-aktif
    </span>
  );
}

export function Card({ children, className = '' }) {
  return (
    <div className={`bg-white rounded-2xl border border-gray-100 shadow-sm ${className}`}>
      {children}
    </div>
  );
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
    'inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition disabled:opacity-50 disabled:cursor-not-allowed';
  const variants = {
    primary: 'bg-brand text-white hover:bg-brand-dark',
    danger: 'bg-red-600 text-white hover:bg-red-700',
    ghost: 'bg-gray-100 text-navy hover:bg-gray-200',
    outline: 'border border-gray-300 text-navy hover:bg-gray-50',
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
