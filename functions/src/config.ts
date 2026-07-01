import * as fs from "fs";
import * as path from "path";

/**
 * 환경 설정 로더.
 * functions/env/prod.json (gitignore됨)에서 키를 읽고, 없으면 process.env 폴백.
 * 컴파일 후 __dirname 은 functions/lib 이므로 ../env/prod.json = functions/env/prod.json.
 */
let cached: Record<string, string> | null = null;

function loadEnv(): Record<string, string> {
  if (cached) {
    return cached;
  }
  try {
    const file = path.join(__dirname, "..", "env", "prod.json");
    cached = JSON.parse(fs.readFileSync(file, "utf8")) as Record<string, string>;
  } catch {
    cached = {};
  }
  return cached;
}

export function getGeminiApiKey(): string {
  const env = loadEnv();
  const key = env.GEMINI_API_KEY || process.env.GEMINI_API_KEY || "";
  if (!key) {
    throw new Error(
      "GEMINI_API_KEY 가 없어요. functions/env/prod.json 에 값을 넣어주세요."
    );
  }
  return key;
}

export function getKakaoRestApiKey(): string {
  const env = loadEnv();
  const key = env.KAKAO_REST_API_KEY || process.env.KAKAO_REST_API_KEY || "";
  if (!key) {
    throw new Error(
      "KAKAO_REST_API_KEY 가 없어요. functions/env/prod.json 에 값을 넣어주세요."
    );
  }
  return key;
}

/// 카카오 Client Secret (보안 설정에서 활성화한 경우만 필요 · 없으면 빈 문자열)
export function getKakaoClientSecret(): string {
  const env = loadEnv();
  return env.KAKAO_CLIENT_SECRET || process.env.KAKAO_CLIENT_SECRET || "";
}
