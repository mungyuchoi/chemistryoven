import { getAuth } from "firebase-admin/auth";
import { onCall, HttpsError } from "firebase-functions/v2/https";

// Node 22 글로벌 fetch (별도 타입 의존 없이 최소 선언)
declare const fetch: (
  input: string,
  init?: { headers?: Record<string, string> }
) => Promise<{ ok: boolean; json(): Promise<unknown> }>;

/**
 * 카카오 로그인 → Firebase 커스텀 토큰 발급.
 *
 * 흐름(클라이언트):
 *  1) kakao_flutter_sdk 로 카카오 로그인 → access token 획득
 *  2) 이 함수를 호출({ accessToken }) → firebaseToken 수신
 *  3) FirebaseAuth.signInWithCustomToken(firebaseToken)
 *
 * 이 함수는 access token 으로 카카오 사용자 정보를 조회하고
 * uid `kakao:{id}` 로 Firebase 사용자(없으면 생성)를 매핑해 커스텀 토큰을 만든다.
 */
export const createKakaoCustomToken = onCall(
  { region: "asia-northeast3" },
  async (req) => {
    const accessToken = req.data?.accessToken as string | undefined;
    if (!accessToken) {
      throw new HttpsError("invalid-argument", "accessToken이 필요해요.");
    }

    // 카카오 사용자 정보 조회
    const res = await fetch("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!res.ok) {
      throw new HttpsError("unauthenticated", "카카오 인증에 실패했어요.");
    }
    const kakao = (await res.json()) as {
      id?: number;
      kakao_account?: {
        profile?: { nickname?: string; profile_image_url?: string };
      };
    };

    const kakaoId = kakao.id?.toString();
    if (!kakaoId) {
      throw new HttpsError("internal", "카카오 사용자 ID를 받지 못했어요.");
    }

    const uid = `kakao:${kakaoId}`;
    const profile = kakao.kakao_account?.profile ?? {};
    const displayName = profile.nickname ?? "카카오사용자";
    const photoURL = profile.profile_image_url;

    // Firebase 사용자 생성/갱신 (email은 타 제공자와 충돌 방지를 위해 미설정)
    try {
      await getAuth().updateUser(uid, { displayName, photoURL });
    } catch {
      await getAuth().createUser({ uid, displayName, photoURL });
    }

    const firebaseToken = await getAuth().createCustomToken(uid, {
      provider: "kakao",
    });
    return { firebaseToken };
  }
);
