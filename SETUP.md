# SETUP.md — 오늘 저녁 세팅 가이드

## 0. 챙길 파일 (이 채팅에서 다운로드)
- hiking_seed_data.zip  ← 시드 데이터 (CSV 6개 + schema.sql + README)
- CLAUDE.md             ← 프로젝트 헌법 (레포 루트에 둘 것)
- BACKLOG.md            ← 마일스톤 백로그 (레포 루트에 둘 것)
- SETUP.md              ← 이 파일

## 1. 직접 할 일 (Claude Code가 못 하는 것들, 약 30-40분)

### GitHub
- [ ] 새 레포 생성 (공개/비공개 선택)
- [ ] 로컬 클론 후 CLAUDE.md, BACKLOG.md, SETUP.md 넣고 첫 커밋
- [ ] 시드 데이터는 seed/ 폴더로 압축 해제해서 같이 커밋 (공공데이터라 라이선스 OK)

### Supabase (supabase.com)
- [ ] 새 프로젝트 생성 (리전: Northeast Asia - Seoul)
- [ ] SQL Editor에서 seed/schema.sql 전체 실행
- [ ] Table Editor > 각 테이블 > Import data via CSV, 순서대로:
      mountains → nodes → segments → spots → safety_points
      (entrances.csv는 임포트 안 함 — 뷰로 이미 존재)
- [ ] Project Settings > API에서 두 값 복사해두기:
      Project URL, anon public key
- 확인: SQL Editor에서 `select count(*) from segments;` → 1732 나오면 성공

### 네이버 클라우드 플랫폼 (지도 키)
- [ ] ncloud.com 가입 > 콘솔 > Maps > Application 등록
- [ ] Mobile Dynamic Map 선택, Android 패키지명/iOS 번들ID에 **com.woosan.sannote** 등록
- [ ] Client ID 복사해두기

### 로컬
- [ ] FVM으로 Flutter 버전 고정: `fvm install stable && fvm use stable` (레포 폴더에서)
      → 생성된 .fvmrc는 커밋, .fvm/은 .gitignore
- [ ] IDE의 Flutter SDK 경로를 .fvm/flutter_sdk로 지정
- [ ] Claude Code 설치: npm install -g @anthropic-ai/claude-code
      (요금제/설치 상세: https://docs.claude.com/en/docs/claude-code/overview)

## 2. Claude Code 첫 프롬프트 (레포 폴더에서 `claude` 실행 후 붙여넣기)

---
CLAUDE.md와 BACKLOG.md를 읽고 M0을 진행해줘.

추가 정보:
- Supabase URL: <여기 붙여넣기>
- Supabase anon key: <여기 붙여넣기>
- 네이버 지도 Client ID: <여기 붙여넣기>
- 앱 이름: 산노트 (sannote)
- 번들 ID: com.woosan.sannote

주의사항:
- Flutter는 FVM으로 고정돼 있어. 모든 flutter/dart 명령은 fvm flutter, fvm dart로 실행해.
- 키들은 .env 파일 + flutter_dotenv로 관리하고 .gitignore에 .env 추가.
  .env.example 파일을 만들어서 레포에는 키 없이 커밋해줘.
- Supabase에는 시드 데이터가 이미 임포트돼 있어 (segments 1,732행).
  스키마를 새로 만들지 말고 연결만 해.
- M0 완료 조건(mountains 7건 콘솔 출력)까지 확인되면,
  BACKLOG.md 체크박스 갱신하고 M1 시작 전에 나한테 보고해줘.
---

## 3. 이후 루프
- 마일스톤 끝날 때마다: 결과 확인 → BACKLOG.md의 🔴 결정 내려주기 → "다음 진행해"
- 기획 고민/데이터 작업이 생기면: claude.ai 채팅으로 (이 대화 검색해서 이어감)
- 새 아이디어가 떠오르면: 구현하지 말고 BACKLOG.md 아이디어 메모에 적기

## 흔한 첫날 함정
- 네이버 지도 키의 패키지명/번들ID가 프로젝트와 다르면 지도가 회색으로만 나옴
- Supabase 무료 티어는 1주 미사용 시 일시정지 → 대시보드에서 Resume
- CSV 임포트 시 segments.polyline이 text로 들어가면: 당장은 동작에 문제없음.
  나중에 `alter table segments alter column polyline type jsonb using polyline::jsonb;`
