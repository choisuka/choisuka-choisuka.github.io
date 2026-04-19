const fs = require('fs');
const path = require('path');
const vm = require('vm');

// 1. HTML 파일 읽기
const html = fs.readFileSync('C:/Users/USER/toro_math/index.html', 'utf8');

// 2. CARD_DATA 추출
const startIdx = html.indexOf('const CARD_DATA = {');
const endIdx = html.indexOf('\n};\n', startIdx) + 4;
let cardDataStr = html.slice(startIdx, endIdx);

// 3. Node.js에서 평가 (const → 전역 할당으로 변환)
cardDataStr = cardDataStr.replace('const CARD_DATA', 'CARD_DATA');
const sandbox = { localStorage: { getItem: () => null, setItem: () => {} } };
try {
  vm.runInNewContext(cardDataStr, sandbox);
} catch(e) {
  console.error('파싱 오류:', e.message);
  process.exit(1);
}
const CARD_DATA = sandbox.CARD_DATA;

// 4. 카드셋 → 단계/토픽 매핑 (hs- 제외)
const STAGE_MAP = {
  'fm-guide':               '1단계_약수배수',
  'fm-gcd':                 '1단계_약수배수',
  'fm-worksheet':           '1단계_약수배수',
  'fm-advanced':            '1단계_약수배수',
  'fm-hard10':              '1단계_약수배수',
  'fm-solution':            '1단계_약수배수',
  'prime-havruta':          '1단계_소인수분해',
  'eq-guide':               '2단계_방정식',
  'eq-basic':               '2단계_방정식',
  'eq-hard':                '2단계_방정식',
  'eq-identity':            '2단계_방정식',
  'eq-identity-havruta':    '2단계_방정식',
  'eq-havruta-cards':       '2단계_방정식',
  'eq-identity-discussion': '2단계_방정식',
  'eq-guarantee':           '2단계_방정식',
  'inequality-guide':       '2단계_부등식',
  'inequality-havruta':     '2단계_부등식',
  'ineq-hard10':            '2단계_부등식',
  'ineq-gemini5':           '2단계_부등식',
  'ineq-lesson':            '2단계_부등식',
  'simultaneous-guide':     '2단계_연립방정식',
  'simultaneous-basic':     '2단계_연립방정식',
  'simultaneous-hard':      '2단계_연립방정식',
  'simultaneous-havruta':   '2단계_연립방정식',
  'linear-func-guide':      '3단계_일차함수',
  'linear-func-havruta':    '3단계_일차함수',
  'linear-func-deep':       '3단계_일차함수',
  'poly-guide':             '3단계_다항식',
  'poly-havruta':           '3단계_다항식',
  'poly-hard':              '3단계_다항식',
  'quad-eq-guide':          '3단계_이차방정식',
  'quad-eq-havruta':        '3단계_이차방정식',
  'complex-guide':          '3단계_복소수',
  'complex-havruta':        '3단계_복소수',
  'quad-func-guide':        '3단계_이차함수',
  'quad-func-havruta':      '3단계_이차함수',
  'quadratic-guide':        '3단계_이차함수',
  'quadratic-havruta':      '3단계_이차함수',
  'geometry-guide':         '4단계_도형',
  'geometry-havruta':       '4단계_도형',
  'avg-guide':              '4단계_통계',
  'avg-hard':               '4단계_통계',
  'avg-example':            '4단계_통계',
  'avg-havruta':            '4단계_통계',
};

// 5. HTML 파일 생성 함수
function makeHTML(card, filename, stage, setKey, num, total) {
  const ansSection = card.ans ? `
  <details style="margin-top:1rem">
    <summary style="cursor:pointer;display:inline-block;padding:.6rem 1.6rem;background:linear-gradient(135deg,#86efac,#3b82f6);border:none;border-radius:999px;color:#0f172a;font-weight:700;font-size:.9rem;list-style:none">
      ✅ 정답 보기
    </summary>
    <div style="margin-top:.6rem;background:#0f172a;border:1px solid rgba(134,239,172,.2);border-radius:16px;padding:1.2rem 1.6rem;color:#e2e8f0;line-height:1.9;font-size:.9rem">
      ${card.ans}
    </div>
  </details>` : '';

  return `<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${card.tag} — 아르모니아 수학왕국</title>
</head>
<body style="margin:0;padding:20px;background:#0f172a;min-height:100vh;display:flex;align-items:center;justify-content:center">
<div style="max-width:580px;width:100%;font-family:'Noto Sans KR',sans-serif">

  <div style="font-size:.75rem;color:#94a3b8;margin-bottom:.5rem">
    📚 아르모니아 수학왕국 · ${stage.replace('_',' ')} · ${setKey} ${num}/${total}
  </div>

  <div style="display:inline-block;padding:.3rem .9rem;border-radius:999px;background:${card.bg};border:1px solid ${card.bd};color:${card.tagColor};font-size:.8rem;font-weight:700;margin-bottom:.8rem">
    ${card.tag}
  </div>

  <div style="background:${card.bg};border:1px solid ${card.bd};border-radius:16px;padding:1.4rem 1.6rem;line-height:1.85;font-size:.9rem">
    ${card.body}
  </div>

  ${ansSection}

  <div style="margin-top:1rem;text-align:right;font-size:.75rem">
    <a href="https://choisuka.github.io/toro_math/" style="color:#7dd3fc;text-decoration:none">
      🏰 아르모니아 수학왕국 전체 보기 →
    </a>
  </div>

</div>
</body>
</html>`;
}

// 6. 출력 폴더
const outDir = 'C:/Users/USER/toro_math/blog_cards';
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);

// 7. 파일 생성
let total = 0;
for (const [setKey, stage] of Object.entries(STAGE_MAP)) {
  const cards = CARD_DATA[setKey];
  if (!cards || !cards.length) continue;
  cards.forEach((card, i) => {
    const num = String(i + 1).padStart(2, '0');
    const filename = `${stage}_${setKey}_${num}.html`;
    const filepath = path.join(outDir, filename);
    fs.writeFileSync(filepath, makeHTML(card, filename, stage, setKey, i+1, cards.length), 'utf8');
    total++;
  });
  console.log(`✓ ${stage}_${setKey}: ${cards.length}개`);
}
console.log(`\n✅ 총 ${total}개 파일 생성 완료`);
