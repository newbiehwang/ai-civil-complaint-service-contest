import { PrimaryButton } from '../components/PrimaryButton';
import { Gov24Badge } from '../components/Gov24Badge';
import './ComplaintStartScreen.css';

export function ComplaintStartScreen() {
  return (
    <main className="start-screen" data-node-id="3:3">
      <section className="mobile-frame">
        <div className="hero-block">
          <Gov24Badge />
          <p className="hero-tag">정부24 연동 · AI 민원 도우미</p>
          <h1>시작하기 전에, 민원 핵심을 1분 안에 정리해드릴게요.</h1>
          <p className="hero-description">
            대화형 질문에 답하면 제출 초안과 증거 체크리스트를 바로 준비합니다.
          </p>
        </div>

        <ul className="feature-list" aria-label="시작 안내">
          <li>
            <strong>접수 요약 자동 생성</strong>
            <span>복잡한 내용을 핵심 문장으로 압축합니다.</span>
          </li>
          <li>
            <strong>증거 체크</strong>
            <span>부족한 항목을 바로 알려 제출 실패를 줄입니다.</span>
          </li>
          <li>
            <strong>진행상태 추적</strong>
            <span>접수 후 단계별 타임라인을 한눈에 확인합니다.</span>
          </li>
        </ul>

        <div className="start-cta">
          <PrimaryButton label="시작하기" />
          <p className="cta-caption">평균 2분 · 언제든 중단 후 이어하기 가능</p>
        </div>
      </section>
    </main>
  );
}
