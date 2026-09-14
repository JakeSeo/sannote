# CLAUDE.md — 산노트 (sannote)

## 프로젝트 개요
수도권 2030 등산 초보를 위한 등산 코스 정보 앱.
핵심 가치: 산 단위가 아니라 **입구·코스 단위의 큐레이션** ("아차산역 출발 2시간 초보 코스").
v1은 정보+기록 앱. GPS 실시간 트래킹은 v2 이후 (BACKLOG.md 참조).

## 확정된 결정 (변경하려면 먼저 물어볼 것)
- 앱 이름: 산노트 (sannote) / 번들 ID·패키지명: **com.woosan.sannote** (Android·iOS 동일)
- Flutter: **FVM으로 버전 고정** (.fvmrc 기준). flutter 명령은 항상 `fvm flutter ...`로 실행
- 폰 우선 + 태블릿 반응형 대응
- 백엔드: Supabase (인증/Postgres/Storage)
- 지도: flutter_naver_map (네이버 지도 SDK)
- 상태관리: Riverpod (DI + ViewModel은 Notifier)
- **아키텍처: 클린 아키텍처 + MVVM.** 의존 방향은 한 방향으로만:
  `Supabase → Service → Repository → UseCase → ViewModel → UI`
  - `features/<기능>/data/services/` — Supabase 호출, 원시 행(Map)만 다룸
  - `features/<기능>/data/repositories/` — Service 결과를 도메인 엔티티로 매핑 (RepositoryImpl)
  - `features/<기능>/domain/entities|repositories|usecases/` — 엔티티, 리포지토리 인터페이스, 유즈케이스. 지도 SDK·Supabase 타입 import 금지
  - `features/<기능>/presentation/viewmodels/` — Notifier<State>. UseCase만 호출, Flutter 위젯 import 금지
  - `features/<기능>/presentation/views/` — 위젯. ViewModel 상태만 보고 그림. 비즈니스 로직 금지
  - 각 레이어의 Provider는 해당 클래스 파일에 함께 둠 (xxxServiceProvider → xxxRepositoryProvider → xxxUseCaseProvider → xxxViewModelProvider)
- 사진 스토리지: 초기엔 Supabase Storage, 트래픽 증가 시 Cloudflare R2 이전
- 코스는 자동 생성하지 않음. 운영자가 큐레이션 (courses.segment_ids 수동 입력)
- **저장 구조: GPS 트랙은 로컬(drift/sqlite)만. 서버 visits에는 메타데이터만**
  (course_id, 날짜, 소요시간 — 트랙 폴리라인·좌표는 서버에 올리지 않음)
- 인증: v1은 Supabase 익명 로그인. 소셜 로그인은 v2 계정 연동으로
- 톤앤매너: **숲** (진녹 주색 + 미색 바탕 + 둥근 카드, 코스·강조는 주황). 정의는 lib/core/theme/app_theme.dart 한 곳에서만

## 데이터 구조 (시드 임포트 완료 상태 기준)
- mountains(7 산군) / nodes(1,328) / segments(1,732) / spots(3,716) / safety_points(97)
- segments.polyline = [[lon,lat],...] WGS84 jsonb — 지도에 바로 그릴 수 있음
- segments.start_node/end_node로 그래프 연결. nodes.degree 3+ = 갈림길
- segments.park_flag=1 은 공원 산책로형 — 등산 코스 구성에서 기본 제외
- courses.segment_ids(jsonb 배열)를 순서대로 이어붙이면 코스 폴리라인
- **주의: 고도 데이터 없음** (원본 ele=0). 고도 그래프 기능은 만들지 말 것 (백로그 M6)
- 산 이름은 유니크하지 않음(동명이산). 식별은 항상 mountain_group/코드로

## 코딩 규칙
- **위치 스트림은 반드시 추상화** (LocationService 인터페이스):
  실제 GPS(geolocator)와 MockLocationService를 교체 가능하게.
  Mock은 코스 polyline 좌표를 설정한 간격(기본 15초)으로 재생 —
  약간의 좌표 노이즈(±10m)와 속도 배율 옵션 포함 (1시간 산행을 1분에 재생).
  디버그 빌드에만 mock 전환 스위치 노출 (개발자 메뉴), 릴리즈에는 실제 GPS만.
  GPS 관련 기능(기록/색칠/visits 전송)은 전부 mock으로 책상에서 테스트 가능해야 함.
- 기능은 현재 마일스톤 범위만. 범위 밖 아이디어는 구현하지 말고 BACKLOG.md에 메모 추가
- 새 패키지 추가 전에 이유와 함께 제안 먼저
- 화면은 폰 기준으로 만들되 LayoutBuilder로 태블릿 레이아웃 분기 자리만 마련
- 커밋은 기능 단위로 잘게, 메시지는 한국어 명령형 ("코스 상세 고도 정보 표시")
- 에러 처리: Supabase 호출은 전부 try-catch + 사용자용 스낵바, 콘솔에 상세 로그
- 하드코딩 금지: 산/코스 데이터는 반드시 DB에서. 더미 데이터 필요 시 아차산 실데이터 사용

## 안전 원칙 (중요)
- 길 안내·자동 판정 기능엔 항상 사용자 수동 확인 단계를 넣을 것
- safety_points(구조 표지판)는 "참고용" 라벨과 함께 표시 (2016년 데이터, 실물 검증 전)
- 앱 어디에도 "이 길은 안전하다"는 단정 표현 금지. 소요시간은 "예상" 표기

## 운영자 도구·마이그레이션
- DDL은 `supabase/migrations/*.sql`에 번호 순으로 두고, 사용자가 SQL Editor에서 직접 실행 (publishable key로 DDL 불가)
- 데이터 입력은 `tools/*.py` 스크립트(표준 라이브러리만, `.env` 읽음). 어드민 화면 만들지 않음
- 디버그 전용 진입: `--dart-define=SANNOTE_START=explore|mountain:<산군>|course:<id>`, `SANNOTE_THEME=forest|dawn`
- 개발자 메뉴: 탐색 탭 제목 길게 누르기 (kDebugMode 에서만)

## 세션 시작 시
1. BACKLOG.md에서 현재 마일스톤 확인
2. 마일스톤의 완료 조건(AC)을 기준으로 작업
3. 완료 시 BACKLOG.md 체크박스 갱신 + 다음 결정 포인트를 사용자에게 보고
