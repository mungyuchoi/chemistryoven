import { GoogleGenerativeAI } from "@google/generative-ai";
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";

import { getGeminiApiKey } from "./config";
import {
  SCORE_SELECTION_PROMPT,
  SCORE_SELECTION_OUTPUT_INSTRUCTION,
} from "./prompts";

initializeApp();
const db = getFirestore();

// 우리 프로젝트 리전(서울)
setGlobalOptions({ region: "asia-northeast3" });

interface ParticipantInput {
  uid: string;
  gender: string | null;
  birth: string | null;
  height: number | null;
  mbti: string | null;
  region: string | null;
  preferences: unknown;
  answers: unknown;
}

/** 배포/연결 확인용 헬스체크 */
export const ping = onCall((req) => {
  return { ok: true, uid: req.auth?.uid ?? null, time: Date.now() };
});

/** 운영자 권한 확인 (users/{uid}.roles 에 'admin') */
async function assertAdmin(uid?: string): Promise<void> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "로그인이 필요해요.");
  }
  const snap = await db.doc(`users/${uid}`).get();
  const roles = (snap.data()?.roles ?? []) as string[];
  if (!roles.includes("admin")) {
    throw new HttpsError("permission-denied", "운영자만 사용할 수 있어요.");
  }
}

/**
 * 케미 점수 계산 & 인원 선정 (Gemini 2.5 Flash Lite).
 * 입력: { sessionId }
 * 동작: 회차 신청자 + 사용자 온보딩 데이터를 모아 Gemini에 전달 →
 *      점수를 applications/{uid} 에, 테이블 구성을 sessions/{id} 에 저장.
 */
export const computeChemistryScores = onCall(
  { timeoutSeconds: 300, memory: "512MiB" },
  async (req) => {
    await assertAdmin(req.auth?.uid);

    const sessionId = req.data?.sessionId as string | undefined;
    if (!sessionId) {
      throw new HttpsError("invalid-argument", "sessionId가 필요해요.");
    }

    // 신청자 + 사용자 데이터 수집
    const appsSnap = await db
      .collection(`sessions/${sessionId}/applications`)
      .get();

    const participants: ParticipantInput[] = [];
    for (const appDoc of appsSnap.docs) {
      const uid = appDoc.id;
      const userSnap = await db.doc(`users/${uid}`).get();
      const u = userSnap.data() ?? {};
      const onboarding = (u.onboarding ?? {}) as Record<string, unknown>;
      participants.push({
        uid,
        gender: (u.gender ?? appDoc.data().gender ?? null) as string | null,
        birth: (u.birth ?? null) as string | null,
        height: (u.height ?? null) as number | null,
        mbti: (u.mbti ?? null) as string | null,
        region: (u.region ?? null) as string | null,
        preferences: onboarding.preferences ?? null,
        answers: onboarding.answers ?? null,
      });
    }

    if (participants.length === 0) {
      throw new HttpsError("failed-precondition", "신청자가 없어요.");
    }

    // Gemini 호출 (JSON 모드)
    const genAI = new GoogleGenerativeAI(getGeminiApiKey());
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash-lite",
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.4,
      },
    });

    const prompt =
      `${SCORE_SELECTION_PROMPT}\n\n${SCORE_SELECTION_OUTPUT_INSTRUCTION}\n\n` +
      `[참가자 데이터]\n${JSON.stringify(participants)}`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    let parsed: {
      drops?: unknown[];
      scores?: Array<{
        uid?: string;
        strict?: number;
        psychology?: number;
        total?: number;
      }>;
      tables?: unknown[];
    };
    try {
      parsed = JSON.parse(text);
    } catch {
      throw new HttpsError("internal", "AI 응답을 해석하지 못했어요.");
    }

    // 결과 저장
    const batch = db.batch();
    for (const s of parsed.scores ?? []) {
      if (!s.uid) {
        continue;
      }
      batch.set(
        db.doc(`sessions/${sessionId}/applications/${s.uid}`),
        {
          strictScore: s.strict ?? null,
          psychologyScore: s.psychology ?? null,
          totalScore: s.total ?? null,
          scoredAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
    batch.set(
      db.doc(`sessions/${sessionId}`),
      {
        tables: parsed.tables ?? [],
        drops: parsed.drops ?? [],
        status: "selecting",
        scoredAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    await batch.commit();

    return {
      ok: true,
      participantCount: participants.length,
      tables: parsed.tables ?? [],
    };
  }
);
