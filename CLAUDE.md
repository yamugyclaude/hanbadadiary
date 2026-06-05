# SoundLog — 한바다 작업일지

음향 행사 관리 앱. 단일 파일 SPA로, 모든 코드가 `index.html` 하나에 있습니다.

---

## 기술 스택

| 항목 | 내용 |
|---|---|
| 파일 구조 | `index.html` 단일 파일 (HTML + CSS + JS 일체) |
| 백엔드 | Supabase (REST API + Realtime WebSocket) |
| 배포 | GitHub Pages (`git push origin main` → 자동 배포) |
| 저장소 | https://github.com/yamugyclaude/hanbadadiary |
| 라이브 URL | https://yamugyclaude.github.io/hanbadadiary/ |

---

## Supabase 설정

- **URL**: `https://nifmnigvrjfctdimgmda.supabase.co`
- **Key**: 코드 내 `SB_KEY` 상수 참조 (anon key)

### 테이블 구조

| 테이블 | 용도 |
|---|---|
| `soundlogs` | 행사일지 (id, date, event_name, data, md_content) |
| `tasks` | 창고/사무실/대표지시 업무 (id, type, title, body, status, priority, due, data) |
| `vehicle_data` | 차량·체크리스트·장비·알바 데이터 통합 저장 |
| `access_logs` | 접속·행동 로그 |

### vehicle_data 행 구조

| id | 저장 내용 |
|---|---|
| `singleton` | 차량 정비 데이터 (v15·v35 combined) |
| `sl_users` | 사용자 계정 배열 |
| `checklist` | 행사 전 체크리스트 items + checked 상태 |
| `equipment` | 장비관리대장 (음향·무대·사무실·조명·특효·기타) |
| `alba` | 알바관리 (workers + schedules) |

---

## 인증 시스템

- **로그인 계정**: `id='hanbada'`, `pw='2375'` (앱 최초 실행 시 자동 생성)
- **수정·삭제 암호**: `2375` (전 기능 공통)
- **회원가입 승인 코드**: `REGISTER_CODE = '2375'`
- 로그인: `doLogin()` — 로컬 미발견 시 클라우드 자동 조회
- 사용자 데이터: `vehicle_data` 테이블 `id='sl_users'` 행에 JSON 배열로 저장

---

## 전체 탭 구조

| 탭 | 페이지 ID | 설명 |
|---|---|---|
| 📋 행사일지 | `pageList` / `pageForm` | 행사 기록 작성·조회, 사진 업로드 |
| 📅 일정 | `pageCalendar` | 구글 캘린더 연동 |
| 🏭 창고업무 | `pageWarehouse` | 업무 카드 관리 |
| 🏢 사무실업무 | `pageOffice` | 업무 카드 관리 |
| 👔 대표지시 ▾ | `pageDirective` | 지시사항 관리 (클릭 시 드롭다운) |
| └ 👷 알바관리 | `pageAlba` | 알바 명단 + 스케줄 관리 |
| 🚛 차량관리 | `pageVehicle` | 1.5톤·3.5톤 정비 기록 |
| 🗂️ 장비관리 | `pageEquipment` | 장비 카드형 관리대장 |

### 탭 내비게이션
- 가로 스크롤 한 줄 (탭 늘어나도 레이아웃 안 깨짐)
- 오른쪽/왼쪽 페이드 화살표로 더 있음 표시
- `대표지시` 탭 클릭 → 드롭다운 메뉴 (대표지시 / 알바관리)

---

## 주요 기능 상세

### 📋 행사일지
- 행사 기록 작성 (콘솔, 스피커, 마이크, 전기, 이슈 등)
- 사진 업로드 4장 × 2섹션 (음향장비, 무대설치)
- 자동저장 (로컬 800ms, 클라우드 3초)
- MD 내보내기

### 📋 행사 전 체크리스트 (로그인 화면 위)
- 카테고리: 무대설치 / 음향설치 / 우천시 / 장비관리대장
- 항목 추가·수정·삭제 (삭제 암호 2375)
- 체크 시 줄긋기, 초기화 버튼
- 진행률 표시 (n/n)
- 섹션 헤더 아이템 (`【 ... 】` 시작) — 체크 불가 구분선
- 장비관리대장 카테고리: PDF 3개 기반 55개 기본 항목 자동 탑재
- 💾 저장 / ☁️ 불러오기 수동 버튼
- Supabase 클라우드 동기화 + Realtime

### 🚛 차량관리
- 1.5톤 포터 / 3.5톤 마이티 분리 관리
- 정비 기록 추가·삭제
- 보험·검사 만료일 D-day 표시
- v15·v35 데이터를 `v15` 컬럼 하나에 combined 포맷으로 저장

### 🗂️ 장비관리대장
- 카테고리: 음향장비 / 무대장비 / 사무실장비 / 조명장비 / 특효장비 / 기타장비
- 카드 형태로 장비 목록 표시
- 장비 클릭 → 팝업 상세 (장비명, 구분, 모델, 수량, 납품업체, 시리얼번호, 담당자, 연락처, 상태)
- 사진 업로드 최대 4장 (800px 리사이즈, 클릭 시 라이트박스 확대)
- 관리내역 로그 (날짜·내용·업체, 삭제 암호 2375)
- 구분 태그 + 통합 검색 (전체 카테고리 검색)
- 사용중 / 미사용 상태 필터
- PDF 3개 기반 기본 장비 57종 자동 탑재
- Supabase `id='equipment'` 저장

### 👷 알바관리
- **알바 명단 탭**: 알바 카드 (이름·연락처·역할·스케줄 건수)
- **스케줄 탭**: 월별 스케줄 목록 (날짜·시간·행사명·급여)
- 알바 클릭 → 팝업 (기본정보 + 스케줄 이력 + 스케줄 추가)
- 등록·수정·삭제·스케줄 삭제 모두 암호 2375
- Supabase `id='alba'` 저장

---

## 동기화 구조

```
저장/변경
  → localStorage 즉시 업데이트
  → Supabase REST API upsert (백그라운드)

다른 기기
  → WebSocket Realtime 수신 (soundlogs, tasks, vehicle_data)
  → localStorage 자동 업데이트 + 화면 자동 갱신
```

### Realtime 구독 테이블
- `soundlogs` — 행사일지
- `tasks` — 업무(창고·사무실·대표지시)
- `vehicle_data` — 차량·체크리스트·장비·알바·사용자

---

## 모바일 최적화 사항
- 모든 모달 하단 `✕ 닫기` 버튼 (아이폰 엄지 접근용)
- `env(safe-area-inset-bottom)` 적용 (홈 인디케이터 대응)
- 탭 가로 스크롤 + 좌우 페이드 화살표 인디케이터
- 버튼 최소 터치 영역 44×44px

---

## 배포 방법

```bash
# 수정 후
git add index.html CHANGELOG.md
git commit -m "feat/fix: 변경 내용 요약"
git push origin main
# → GitHub Pages 자동 배포 (약 30초~1분 소요)
```

---

## 다른 기기에서 작업 시작하는 법

```bash
# 1. 저장소 클론 (최초 1회)
git clone https://github.com/yamugyclaude/hanbadadiary.git
cd hanbadadiary

# 2. 최신 코드 받기 (이미 클론된 경우)
git pull origin main

# 3. Claude Desktop 또는 Claude Code 실행
claude
```

> Claude가 이 `CLAUDE.md`를 자동으로 읽어 프로젝트 맥락을 즉시 파악합니다.
> 새 대화에서 "한바다작업일지 이어서 작업하자" 라고 하면 됩니다.

---

## 작업 이력 요약 (2026-05-28 ~ 2026-06-05)

| 날짜 | 작업 내용 |
|------|----------|
| 2026-05-28 | 3.5톤 마이티 정비 기록 저장 버그 수정 (maintenance 배열 초기화 누락) |
| 2026-05-28 | v35 컬럼 제거 → v15 컬럼에 combined 포맷으로 통합 저장 |
| 2026-05-28 | `_syncVehicleCloud()` 백그라운드 동기화 함수 신설 |
| 2026-06-04 | 행사 전 체크리스트 신설 (로그인 화면 위, 4개 카테고리) |
| 2026-06-04 | 체크리스트 장비관리대장 카테고리 + PDF 기반 55개 항목 탑재 |
| 2026-06-04 | 체크리스트 섹션 헤더 아이템(`【】`) 지원 |
| 2026-06-05 | 🗂️ 장비관리대장 독립 탭 신설 (카드형, 사진, 관리내역) |
| 2026-06-05 | 장비관리 구분 태그 + 통합 검색 추가 |
| 2026-06-05 | 모든 모달 하단 닫기 버튼 추가 (모바일 접근성) |
| 2026-06-05 | 탭 가로 스크롤 + 좌우 화살표 인디케이터 |
| 2026-06-05 | 👷 알바관리 페이지 신설 (명단·스케줄·팝업) |
| 2026-06-05 | 장비 카테고리 개편 (이벤트장비 → 사무실·조명·특효·기타) |
| 2026-06-05 | 계정/암호 전체 변경: admin/6293 → hanbada/2375 |
