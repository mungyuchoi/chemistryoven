#!/usr/bin/env node
/**
 * 오브닝 라이브 플로우 운영/테스트 CLI (Admin SDK).
 *
 * 관리자 화면이 만들어지기 전까지 당일 진행(단계 변경, 매칭 생성 등)을
 * 이 스크립트로 수행한다. 스키마: docs/ARCHITECTURE_PLAN.md §3.4~3.5.
 *
 * 사용법 (functions 디렉터리에서):
 *   node tools/liveFlowAdmin.js seed    --session test-live-8 --email skylife927@gmail.com
 *   node tools/liveFlowAdmin.js stage   test-live-8 firstImpressionChoice
 *   node tools/liveFlowAdmin.js seating test-live-8
 *   node tools/liveFlowAdmin.js match   test-live-8 --email skylife927@gmail.com
 *   node tools/liveFlowAdmin.js report  test-live-8 --email skylife927@gmail.com
 *   node tools/liveFlowAdmin.js status  test-live-8
 *   node tools/liveFlowAdmin.js cleanup test-live-8
 *
 * eventStage 값(= DemoFlowStep enum 이름):
 *   nicknameCheck | firstImpressionChoice | rotationTalk | middleChoice |
 *   seatingGuide | pairBaking | finalChoice | matchResult | chemistryReport | review
 */

const path = require('path');
const admin = require('firebase-admin');

const SA_PATH = path.join(
  __dirname,
  '../env/chemistryoven-firebase-adminsdk-fbsvc-3cbc4b1dd1.json',
);
admin.initializeApp({ credential: admin.credential.cert(require(SA_PATH)) });
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const args = process.argv.slice(2);
const cmd = args[0];
const flag = (name, fallback) => {
  const idx = args.indexOf(`--${name}`);
  return idx >= 0 ? args[idx + 1] : fallback;
};

const STAGES = [
  'nicknameCheck', 'firstImpressionChoice', 'rotationTalk', 'middleChoice',
  'seatingGuide', 'pairBaking', 'finalChoice', 'matchResult',
  'chemistryReport', 'review',
];

// 테스트용 가짜 참가자 (실 운영 시에는 관리자 도구/Functions 가 생성).
const FAKE_PARTICIPANTS = [
  { uid: 'test-p-saltbread', nickname: '소금빵', gender: 'F', profile: { age: 33, job: 'IT/개발', region: '서울', intro: '편해지면 농담이 늘어요. 함께 새로운 걸 해보는 시간을 좋아합니다.', taste: ['맛집', '영화', '러닝'], dessert: ['담백한 빵', '커피와 잘 맞는'], drink: '분위기상 한두 잔', smoke: '비흡연', good: ['말이 잘 통해요', '배려가 자연스러워요', '웃음 코드가 맞아요', '취향이 비슷해요'] } },
  { uid: 'test-p-madeleine', nickname: '마들렌', gender: 'F', profile: { age: 30, job: '디자인/콘텐츠', region: '경기', intro: '차분한 편이지만 한 주제로 깊이 이야기하는 걸 좋아해요.', taste: ['전시', '카페', '독서'], dessert: ['초콜릿', '너무 달지 않은'], drink: '거의 안 마셔요', smoke: '비흡연', good: ['차분해서 편해요', '대화가 깊어져요', '다정해요', '안정감을 줘요'] } },
  { uid: 'test-p-brulee', nickname: '크렘브륄레', gender: 'F', profile: { age: 31, job: '서비스', region: '서울', intro: '새로운 경험을 좋아하고 분위기를 편하게 만드는 편이에요.', taste: ['여행', '맛집', '게임'], dessert: ['크림', '과일'], drink: '가볍게 즐기는 편', smoke: '가끔', good: ['유쾌해요', '센스가 있어요', '분위기를 편하게 해요'] } },
  { uid: 'test-p-montblanc', nickname: '몽블랑', gender: 'M', profile: { age: 32, job: '금융', region: '서울', intro: '운동과 요리를 좋아하는 계획형입니다.', taste: ['헬스', '요리', '캠핑'], dessert: ['밤', '고소한'], drink: '가볍게 즐기는 편', smoke: '비흡연', good: ['성실해요', '리드를 잘해요', '듬직해요'] } },
  { uid: 'test-p-canele', nickname: '카눌레', gender: 'M', profile: { age: 29, job: '마케팅', region: '인천', intro: '사람 이야기 듣는 걸 좋아해요. 주말엔 카페 투어를 다녀요.', taste: ['카페', '사진', '음악'], dessert: ['카눌레', '진한 커피'], drink: '거의 안 마셔요', smoke: '비흡연', good: ['공감을 잘해요', '대화가 편해요', '센스가 있어요'] } },
];

async function findUid(email) {
  const user = await admin.auth().getUserByEmail(email);
  return user.uid;
}

async function myNickname(sessionId, uid) {
  const doc = await db.doc(`sessions/${sessionId}/participants/${uid}`).get();
  return doc.exists ? doc.data().nickname : '티라미수';
}

async function seed() {
  const sessionId = flag('session', 'test-live-8');
  const email = flag('email');
  if (!email) throw new Error('--email <로그인 이메일> 이 필요합니다.');
  const uid = await findUid(email);
  const userDoc = await db.doc(`users/${uid}`).get();
  const gender = (userDoc.exists && userDoc.data().gender) || 'M';
  const displayName = (userDoc.exists && userDoc.data().displayName) || '참가자';

  // 1) 세션 (앱 sessions 탭에도 노출됨)
  await db.doc(`sessions/${sessionId}`).set({
    title: '테스트 · 라이브 오브닝',
    dateText: '2026-07-11',
    timeText: '오후 2:00',
    location: '성수 베이킹 스튜디오 1F',
    priceText: '테스트',
    recruit: { male: 3, female: 3 },
    menuName: '딸기 타르트',
    bakingItems: ['딸기 타르트'],
    allergens: [],
    status: 'ongoing',
    eventStage: 'nicknameCheck',
    notice: '라이브 플로우 검증용 테스트 회차입니다.',
    applicationCount: 6,
    createdBy: 'liveFlowAdmin',
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  // 2) 내 신청 문서 (confirmed → 앱이 이 회차에 attach)
  await db.doc(`sessions/${sessionId}/applications/${uid}`).set({
    uid, displayName, gender,
    status: 'confirmed',
    appliedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  // 3) 참가자: 나 + 가짜 5명 (내 성별에 따라 이성 후보가 보이도록 구성됨)
  const batch = db.batch();
  batch.set(db.doc(`sessions/${sessionId}/participants/${uid}`), {
    uid, nickname: '티라미수', gender,
    profile: { age: 30, job: 'IT', region: '서울', intro: '테스트 계정입니다.', taste: ['베이킹', '카페'], dessert: ['티라미수'], drink: '가볍게', smoke: '비흡연', good: ['다정해요'] },
    chemistryScore: 88,
  }, { merge: true });
  for (const p of FAKE_PARTICIPANTS) {
    batch.set(db.doc(`sessions/${sessionId}/participants/${p.uid}`), {
      ...p, chemistryScore: 80 + Math.floor(Math.random() * 15),
    }, { merge: true });
  }
  await batch.commit();

  console.log(`✔ 시드 완료: sessions/${sessionId}`);
  console.log(`  참가자: 나(${uid}, 티라미수) + 가짜 5명`);
  console.log(`  다음: node tools/liveFlowAdmin.js stage ${sessionId} firstImpressionChoice`);
}

async function setStage() {
  const [, sessionId, stage] = args;
  if (!STAGES.includes(stage)) {
    throw new Error(`stage 는 다음 중 하나: ${STAGES.join(' | ')}`);
  }
  await db.doc(`sessions/${sessionId}`).set({ eventStage: stage }, { merge: true });
  console.log(`✔ ${sessionId}.eventStage = ${stage} (앱 화면이 실시간 이동합니다)`);
}

// 좌석 규칙: seatPos 0·1 = 옆자리 페어, 2·3 = 맞은편 페어 (앱과 동일).
async function seedSeating() {
  const [, sessionId] = args;
  const parts = await db.collection(`sessions/${sessionId}/participants`).get();
  const all = parts.docs.map((d) => d.data());
  const fakes = all.filter((p) => p.uid.startsWith('test-p-'));
  const me = all.find((p) => !p.uid.startsWith('test-p-'));
  if (!me) throw new Error('실사용자 참가자가 없습니다. 먼저 seed 를 실행하세요.');

  const opposite = fakes.filter((p) => p.gender !== me.gender);
  const pair = opposite[0] || fakes[0];
  const rest = fakes.filter((p) => p.uid !== pair.uid).slice(0, 2);

  await db.doc(`sessions/${sessionId}/seating/B 테이블`).set({
    tableId: 'B 테이블',
    theme: '딸기 타르트',
    seats: [
      { uid: me.uid, nickname: me.nickname, seatPos: 0 },
      { uid: pair.uid, nickname: pair.nickname, seatPos: 1 },
      { uid: rest[0].uid, nickname: rest[0].nickname, seatPos: 2 },
      { uid: rest[1].uid, nickname: rest[1].nickname, seatPos: 3 },
    ],
    createdAt: FieldValue.serverTimestamp(),
  });
  // participants 문서에도 테이블 반영
  await db.doc(`sessions/${sessionId}/participants/${me.uid}`)
    .set({ tableId: 'B 테이블', seatPos: 0 }, { merge: true });
  console.log(`✔ 자리배치 생성: 내 페어=${pair.nickname}, 맞은편=${rest.map((p) => p.nickname).join(', ')}`);
}

// 내 choices.final.first 상대와 쌍방 매칭 생성 (테스트용 — 실운영은 Functions 판정).
async function makeMatch() {
  const [, sessionId] = args;
  const email = flag('email');
  if (!email) throw new Error('--email 필요');
  const uid = await findUid(email);
  const choices = await db.doc(`sessions/${sessionId}/choices/${uid}`).get();
  const finalPick = choices.exists && choices.data().final && choices.data().final.first;
  const partnerUid = finalPick || 'test-p-saltbread';
  const partnerDoc = await db.doc(`sessions/${sessionId}/participants/${partnerUid}`).get();
  const partnerNick = partnerDoc.exists ? partnerDoc.data().nickname : '소금빵';
  const myNick = await myNickname(sessionId, uid);

  const ref = await db.collection('matches').add({
    sessionId,
    pair: [uid, partnerUid],
    nicknames: { [uid]: myNick, [partnerUid]: partnerNick },
    letters: {
      [partnerUid]: '오늘 반죽 치대면서 나눈 대화가 참 편안했어요. 다음엔 천천히 커피 한잔 해요 :)',
    },
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log(`✔ 매칭 생성: matches/${ref.id} (${myNick} ↔ ${partnerNick})`);
  console.log('  앱 매칭 결과 화면이 "집계 중" → 편지로 바뀝니다.');
}

async function makeReport() {
  const [, sessionId] = args;
  const email = flag('email');
  if (!email) throw new Error('--email 필요');
  const uid = await findUid(email);
  const nick = await myNickname(sessionId, uid);
  const ref = await db.collection('reports').add({
    sessionId, uid,
    model: 'manual-test', promptVersion: 'v0',
    content: {
      nickname: nick,
      summary: `${nick}님은 오늘 대화 주도보다 경청에서 케미가 살아났어요. 첫인상 선택과 최종 선택이 일치한, 확신형 참가자였습니다.`,
      score: 87,
      items: ['첫인상 → 최종까지 선택 일관성 높음', '로테이션에서 “배려가 자연스러워요” 다수 획득', '페어 베이킹 협업 점수 상위 30%'],
    },
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log(`✔ 리포트 생성: reports/${ref.id}`);
}

async function status() {
  const [, sessionId] = args;
  const session = await db.doc(`sessions/${sessionId}`).get();
  if (!session.exists) throw new Error(`sessions/${sessionId} 없음`);
  const s = session.data();
  console.log(`sessions/${sessionId}: status=${s.status} eventStage=${s.eventStage || '(없음)'}`);
  for (const sub of ['applications', 'participants', 'seating', 'choices']) {
    const snap = await db.collection(`sessions/${sessionId}/${sub}`).get();
    console.log(`- ${sub}: ${snap.size}건`);
    snap.forEach((d) => console.log(`    · ${d.id}: ${JSON.stringify(d.data()).slice(0, 160)}`));
  }
  for (const col of ['matches', 'reports']) {
    const snap = await db.collection(col).where('sessionId', '==', sessionId).get();
    console.log(`- ${col}: ${snap.size}건`);
    snap.forEach((d) => console.log(`    · ${d.id}: ${JSON.stringify(d.data()).slice(0, 160)}`));
  }
}

async function cleanup() {
  const [, sessionId] = args;
  if (!sessionId || !sessionId.startsWith('test-')) {
    throw new Error('안전을 위해 test- 로 시작하는 세션만 삭제합니다.');
  }
  for (const sub of ['applications', 'participants', 'seating', 'choices']) {
    const snap = await db.collection(`sessions/${sessionId}/${sub}`).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  for (const col of ['matches', 'reports', 'reviews']) {
    const snap = await db.collection(col).where('sessionId', '==', sessionId).get();
    await Promise.all(snap.docs.map((d) => d.ref.delete()));
  }
  await db.doc(`sessions/${sessionId}`).delete();
  console.log(`✔ ${sessionId} 및 관련 문서 삭제 완료`);
}

const commands = { seed, stage: setStage, seating: seedSeating, match: makeMatch, report: makeReport, status, cleanup };

(async () => {
  if (!commands[cmd]) {
    console.log('명령: seed | stage | seating | match | report | status | cleanup');
    process.exit(1);
  }
  await commands[cmd]();
  process.exit(0);
})().catch((error) => {
  console.error('✖', error.message);
  process.exit(1);
});
