import './PrimaryButton.css';

type PrimaryButtonProps = {
  label: string;
  loading?: boolean;
  disabled?: boolean;
  danger?: boolean;
  onClick?: () => void;
};

export function PrimaryButton({
  label,
  loading = false,
  disabled = false,
  danger = false,
  onClick,
}: PrimaryButtonProps) {
  return (
    <button
      type="button"
      className={`primary-button ${danger ? 'danger' : ''}`}
      onClick={onClick}
      disabled={disabled || loading}
      aria-busy={loading}
    >
      {loading ? '처리 중...' : label}
    </button>
  );
}
