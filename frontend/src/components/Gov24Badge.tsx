import './Gov24Badge.css';

export function Gov24Badge() {
  return (
    <div className="gov24-badge" aria-label="정부24 아이콘">
      <div className="gov24-mark" aria-hidden="true">
        <span className="gov24-ribbon gov24-blue" />
        <span className="gov24-ribbon gov24-green" />
        <span className="gov24-dot">24</span>
      </div>
      <p className="gov24-label">정부24</p>
    </div>
  );
}
