# Chemistry Oven · 앱 아이콘 생성 프롬프트 (512×512)

이미지 생성 라이브러리(Midjourney / DALL·E / Ideogram / Stable Diffusion 등)에 붙여넣어 쓰는 프롬프트 모음입니다.
> 텍스트(한글/영문)를 아이콘에 넣으려면 **Ideogram**처럼 글자 렌더링이 정확한 도구를 추천. 그 외 도구는 **심볼/모노그램** 위주가 안전합니다.

## 브랜드 무드 (프롬프트 공통 톤)
- 소셜 **베이킹 × 케미(궁합) 매칭** 서비스 → "오븐의 따뜻함 + 연결의 스파크 + 디저트의 craft + 프리미엄 로맨스"
- 팔레트: 딥 와인/버건디 `#3B0715` `#9B0D27`, 골드/버터 `#C99542` `#FFE0A5`, 크림/아이보리 `#FFF7EA` `#FFFCF6`, 코코아 `#4A2A22`
- 스타일: 미니멀 · 라운드 · 프리미엄 · 따뜻한 글로우 · 플랫 + 미세한 입체감 (iOS 라운드 스퀘어 아이콘)

---

## ⭐ 추천안 — "오븐 속 피어오르는 하트(소플레)"
오븐 + 케미를 한 심볼로 융합. 텍스트 없이 어느 도구에서나 안전.

```
A premium minimalist mobile app icon, rounded square iOS icon, 512x512, centered composition.
A deep burgundy-to-wine gradient background (#9B0D27 to #3B0715) with a soft warm inner glow.
In the center, an elegant brushed-gold line-art oven with a softly glowing rounded window;
inside the oven, a small stylized heart rising like a soufflé, emitting gentle gold sparkles
(suggesting chemistry and warmth). Cream and butter-gold highlights (#FFE0A5, #C99542),
refined thin golden outlines, subtle rim light, smooth soft shadows.
Modern, cozy, high-end dessert-brand aesthetic, flat vector with delicate depth,
dribbble-quality, crisp clean edges, no text, no clutter.
```
**Negative (SD 계열):** `photorealistic, real text, letters, watermark, busy background, harsh shadows, low contrast, noisy, 3d clay, cartoonish`

---

## 변형안 A — "C·O 골드 모노그램 + 오븐 도어"
글자 느낌을 원하면. 모노그램은 도구가 비교적 잘 그려냅니다.

```
A luxury minimalist app icon, rounded square, 512x512.
Deep wine burgundy gradient background (#3B0715 to #9B0D27) with subtle warm vignette.
Centered: an elegant golden serif monogram "C·O" framed inside a rounded oven door shape,
the oven window glowing softly behind the letters. Brushed gold (#C99542) with cream accents,
fine engraved detailing, premium patisserie branding feel, gentle inner light,
flat with soft dimensional sheen, clean crisp edges, dribbble-quality, no extra text.
```

---

## 변형안 B — "휘스크로 그린 하트"
베이킹 도구 + 로맨스. 매우 미니멀.

```
A minimalist premium app icon, rounded square, 512x512, centered.
Burgundy/wine gradient background with a warm golden glow.
A single elegant gold line-art whisk whose looping wires form a heart shape at the top,
tiny gold sparkles around it. Brushed gold (#C99542) on deep wine (#9B0D27),
cream highlights, thin refined strokes, soft rim light, flat vector with subtle depth,
modern dessert-dating brand, crisp, clean, no text, no clutter.
```

---

## 변형안 C — "디저트 + 케미 스파크"
디저트 캐릭터 정체성을 살림(티라미수/마들렌 등).

```
A high-end minimalist app icon, rounded square, 512x512, centered.
Warm cream-to-butter gradient OR deep wine background (pick one), soft golden ambiance.
A stylized madeleine/financier dessert with a small rising chemistry spark (a tiny glowing
bubble or heart) above it, drawn in elegant brushed-gold line art with cream fill.
Cozy patisserie luxury, fine gold outlines, gentle glow and soft shadow,
flat vector with delicate depth, dribbble-quality, crisp edges, no text.
```

---

## 기술 스펙 & 팁
- **사이즈/형식**: 512×512 (필요 시 1024 생성 후 다운스케일), 정사각, **배경 채움**(투명 X — iOS 아이콘은 불투명).
- **세이프 에어리어**: 중심 심볼을 가장자리에서 ~10% 여백 두고 배치 (모서리 라운딩/마스킹 대비).
- **단순화**: 앱 아이콘은 작게 보이므로 디테일 과하지 않게 — 한 가지 핵심 심볼 + 골드 글로우.
- **색 일관성**: 위 hex 그대로 지정하면 앱 브랜드와 톤이 맞습니다.
- **텍스트**: 한글 "케미스트리오븐" 풀네임은 아이콘에 넣지 않는 걸 권장(가독성·렌더링 문제). 굳이 넣으려면 Ideogram + 모노그램("C·O") 수준으로.
- 생성 후 Flutter 적용: `asset/img/app_icon.png` 교체 → `flutter pub run flutter_launcher_icons` (pubspec의 flutter_launcher_icons 설정 사용).

추천 순서: **추천안 → 변형 A(모노그램)** 두 개를 먼저 뽑아보고 비교해보세요.
