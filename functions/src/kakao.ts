import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";

import { getKakaoRestApiKey, getKakaoClientSecret } from "./config";

// Node 22 글로벌 fetch (별도 타입 의존 없이 최소 선언)
declare const fetch: (
  input: string,
  init?: { method?: string; headers?: Record<string, string>; body?: string }
) => Promise<{
  ok: boolean;
  status: number;
  json(): Promise<unknown>;
  text(): Promise<string>;
}>;

// flutter_web_auth_2 가 잡는 앱 콜백 스킴
const CALLBACK_SCHEME = "chemistryovenoauth";
const REGION = "asia-northeast3";

/**
 * 카카오 로그인 리다이렉트 브리지.
 * 카카오가 보낸 ?code&state 를 앱 커스텀 스킴으로 302 redirect →
 * flutter_web_auth_2 가 캡처한다. (카카오 redirect_uri 에 이 함수 URL 등록)
 */
export const kakaoOauthBridge = onRequest(
  { region: REGION, invoker: "public" },
  (req, res) => {
  const code = req.query.code as string | undefined;
  const state = req.query.state as string | undefined;
  const error = req.query.error as string | undefined;

  const parts: string[] = [];
  if (error) parts.push(`error=${encodeURIComponent(error)}`);
  if (code) parts.push(`code=${encodeURIComponent(code)}`);
  if (state) parts.push(`state=${encodeURIComponent(state)}`);

  res.redirect(`${CALLBACK_SCHEME}://kakao?${parts.join("&")}`);
});

interface KakaoProfile {
  kakaoId: string;
  displayName: string;
  photoURL?: string;
}

/** 인가 코드 → 토큰 교환 → 카카오 사용자 프로필 (공용 헬퍼) */
async function fetchKakaoProfile(
  code: string,
  redirectUri: string
): Promise<KakaoProfile> {
  const clientSecret = getKakaoClientSecret();
  let body =
    `grant_type=authorization_code` +
    `&client_id=${encodeURIComponent(getKakaoRestApiKey())}` +
    `&redirect_uri=${encodeURIComponent(redirectUri)}` +
    `&code=${encodeURIComponent(code)}`;
  if (clientSecret) {
    body += `&client_secret=${encodeURIComponent(clientSecret)}`;
  }

  const tokenRes = await fetch("https://kauth.kakao.com/oauth/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
    },
    body,
  });
  if (!tokenRes.ok) {
    const errText = await tokenRes.text().catch(() => "");
    console.error("[kakao] 토큰 교환 실패:", tokenRes.status, errText);
    throw new HttpsError(
      "unauthenticated",
      `카카오 토큰 교환 실패(${tokenRes.status}): ${errText}`
    );
  }
  const tokenData = (await tokenRes.json()) as { access_token?: string };
  const accessToken = tokenData.access_token;
  if (!accessToken) {
    throw new HttpsError("internal", "카카오 access_token을 받지 못했어요.");
  }

  const meRes = await fetch("https://kapi.kakao.com/v2/user/me", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!meRes.ok) {
    throw new HttpsError("unauthenticated", "카카오 사용자 조회에 실패했어요.");
  }
  const kakao = (await meRes.json()) as {
    id?: number;
    kakao_account?: {
      profile?: { nickname?: string; profile_image_url?: string };
    };
  };
  const kakaoId = kakao.id?.toString();
  if (!kakaoId) {
    throw new HttpsError("internal", "카카오 사용자 ID를 받지 못했어요.");
  }
  const profile = kakao.kakao_account?.profile ?? {};
  return {
    kakaoId,
    displayName: profile.nickname ?? "카카오사용자",
    photoURL: profile.profile_image_url,
  };
}

/**
 * 카카오 로그인: code → Firebase 커스텀 토큰 (새 kakao 계정).
 * 입력: { code, redirectUri }
 */
export const createKakaoCustomToken = onCall(
  { region: REGION },
  async (req) => {
    const code = req.data?.code as string | undefined;
    const redirectUri = req.data?.redirectUri as string | undefined;
    if (!code || !redirectUri) {
      throw new HttpsError("invalid-argument", "code/redirectUri가 필요해요.");
    }

    const { kakaoId, displayName, photoURL } = await fetchKakaoProfile(
      code,
      redirectUri
    );
    const uid = `kakao:${kakaoId}`;
    try {
      await getAuth().updateUser(uid, { displayName, photoURL });
    } catch {
      await getAuth().createUser({ uid, displayName, photoURL });
    }
    const firebaseToken = await getAuth().createCustomToken(uid, {
      provider: "kakao",
    });
    return {
      firebaseToken,
      providerProfile: { nickname: displayName, profileImage: photoURL ?? "" },
    };
  }
);

/**
 * 카카오 본인 인증(계정 생성 X): 현재 로그인 사용자에 카카오 인증 정보 기록.
 * 구글/애플로 로그인한 사용자가 카카오 본인확인만 받을 때 사용.
 * 입력: { code, redirectUri } · 인증된 사용자만.
 */
export const verifyKakaoAccount = onCall({ region: REGION }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "로그인이 필요해요.");
  }
  const code = req.data?.code as string | undefined;
  const redirectUri = req.data?.redirectUri as string | undefined;
  if (!code || !redirectUri) {
    throw new HttpsError("invalid-argument", "code/redirectUri가 필요해요.");
  }

  const { kakaoId, displayName } = await fetchKakaoProfile(code, redirectUri);

  await getFirestore()
    .doc(`users/${uid}`)
    .set(
      {
        kakaoVerified: true,
        kakaoId,
        kakaoNickname: displayName,
        kakaoVerifiedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  return { ok: true, nickname: displayName };
});
