# SoundLog — 한바다 작업일지

음향 행사 관리 앱. 단일 파일 SPA로, 모든 코드가 `index.html` 하나에 있습니다.

---

## ⚠️ 작업 완료 필수 절차 (반드시 지킬 것)

작업이 끝날 때마다 아래 순서를 **빠짐없이** 실행하고 사용자에게 보고한다.

1. **버전 번호 업데이트** — `index.html` 내 버전 표시 (`v0622-XX` 형식)
2. **CHANGELOG.md 기록** — 변경 내용 요약 추가
3. **커밋** — `index.html` + `CHANGELOG.md` 함께
4. **main 머지 & 푸시** — `git push origin main` → GitHub Pages 자동 배포
5. **사용자에게 보고** — "배포 완료. v버전, 변경 내용 요약" 형식으로 보고

> 작업 브랜치에만 푸시하고 보고하는 것은 미완료로 간주한다.

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

> ⚠️ **중요 — 프로젝트가 2개입니다. 절대 혼동 금지.**
> 코드에는 `SB_URL`/`SB_KEY` (DB용)과 `STORAGE_URL`/`STORAGE_KEY` (사진용)이 분리되어 있습니다.
> 어느 한 쪽 URL/키를 바꿀 때 다른 쪽을 덮어쓰지 마세요.

### 1. DB 프로젝트 — 텍스트 데이터 (soundlogs, tasks, vehicle_data 등)

- **대시보드**: `https://supabase.com/dashboard/project/nifmnigvrjfctdimgmda`
- **코드 상수**: `SB_URL = 'https://nifmnigvrjfctdimgmda.supabase.co'`
- **코드 상수**: `SB_KEY` (코드 내 anon key 참조)
- **로그인**: `yamugyhan@gmail.com` (구글 계정)

### 2. Storage 프로젝트 — 사진·파일 (용량 분리, 2026-06-21 신설)

- **대시보드**: `https://supabase.com/dashboard/project/poxafvsqxvcaewduhvxt`
- **코드 상수**: `STORAGE_URL = 'https://poxafvsqxvcaewduhvxt.supabase.co'`
- **코드 상수**: `STORAGE_KEY` (코드 내 anon key 참조)
- **버킷**: `event-photos` (행사사진), `skp-library` (3D 모델)

### 테이블 구조 (DB 프로젝트에만 존재)

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
- 장비 클릭 → 팝업 상세 (장비명, 소분류, 구분, 모델, 수량, 납품업체, 시리얼번호, 담당자, 연락처, 상태)
- 사진 업로드 최대 4장 (800px 리사이즈, 클릭 시 라이트박스 확대)
- 관리내역 로그 (날짜·내용·업체, 삭제 암호 2375)
- 구분 태그 + 통합 검색 (전체 카테고리 검색)
- 사용중 / 미사용 상태 필터
- PDF 3개 기반 기본 장비 57종 자동 탑재
- Supabase `id='equipment'` 저장

#### 음향장비 소분류
- 기본 소분류 6개: 스피커류 / 앰프류 / 프로세서/이퀄라이저 / 콘솔/믹서 / 마이크류 / 케이블/기타
- `soundSubcats` — localStorage에 저장, 추가·수정·삭제 가능
- 전체 보기 시 소분류별 헤더 그룹핑, 소분류 클릭 시 해당 장비만 표시
- ⚙️ 소분류 관리 버튼으로 소분류 CRUD 가능

### 👷 알바관리
- **알바 명단 탭**: 알바 카드 (이름·연락처·역할·스케줄 건수)
- **스케줄 탭**: 월별 스케줄 목록 (날짜·시간·행사명·급여)
- 알바 클릭 → 팝업 (기본정보 + 스케줄 이력 + 스케줄 추가)
- 등록·수정·삭제·스케줄 삭제 모두 암호 2375
- Supabase `id='alba'` 저장

---

## 사진 저장 구조

### 현재 방식: Supabase Storage (2026-06-21 적용)

사진은 **Supabase Storage 버킷**에 파일로 업로드되고, DB에는 **URL 문자열만** 저장됩니다.

```
[사용자가 사진 선택]
  → 브라우저에서 800px 리사이즈 + JPEG 0.7 압축 (약 100~300KB)
  → Supabase Storage 버킷 'event-photos'에 업로드
      경로: soundlogs/{log_id}/sound_0.jpg ~ sound_3.jpg
            soundlogs/{log_id}/stage_0.jpg ~ stage_3.jpg
  → 업로드 성공 시 → soundPhotos[idx] = 공개 URL
  → 업로드 실패 시 → soundPhotos[idx] = base64 (폴백, DB에 저장됨)

[저장 버튼 / 자동저장]
  → base64로 남은 사진 있으면 Storage 재업로드 시도
  → soundlogs.data 컬럼에 URL만 포함된 log 객체 저장

[일지 삭제]
  → Storage에서 해당 log_id 폴더의 파일들 삭제
  → soundlogs 테이블 행 삭제
```

#### 관련 함수

| 함수 | 역할 |
|---|---|
| `uploadPhotoToStorage(logId, type, idx, base64)` | base64 → Storage 업로드, 공개 URL 반환 (실패 시 null) |
| `deletePhotosFromStorage(log)` | log의 soundPhotos·stagePhotos에 있는 Storage URL 파일 전체 삭제 |
| `loadPhoto(type, idx, input)` | 사진 선택 → 리사이즈 → 즉시 Storage 업로드 |
| `saveAndSync()` | base64 남은 사진 마이그레이션 후 DB 저장 |

#### Supabase Storage 최초 설정 (새 환경 구축 시 필수)

Supabase Dashboard에서 아래 2가지를 직접 설정해야 합니다.
anon 키로는 버킷 생성이 불가능하여 코드로 자동화할 수 없습니다.

1. **버킷 생성**: Storage → New Bucket
   - Name: `event-photos`
   - Public bucket: **ON** (체크)

2. **RLS 정책 추가** (버킷 생성 후 Policies 탭):
   - INSERT: `((bucket_id = 'event-photos'::text) AND (role() = 'anon'::text))`
   - UPDATE: 동일
   - DELETE: 동일
   - SELECT: 공개 버킷이므로 별도 설정 불필요

   또는 SQL Editor에서:
   ```sql
   CREATE POLICY "anon can upload event photos"
   ON storage.objects FOR INSERT TO anon
   WITH CHECK (bucket_id = 'event-photos');

   CREATE POLICY "anon can update event photos"
   ON storage.objects FOR UPDATE TO anon
   USING (bucket_id = 'event-photos');

   CREATE POLICY "anon can delete event photos"
   ON storage.objects FOR DELETE TO anon
   USING (bucket_id = 'event-photos');
   ```

#### 이전 방식 (레거시 — 2026-06-21 이전)

사진을 base64 문자열로 인코딩하여 `soundlogs.data` JSON 컬럼에 직접 저장했습니다.

- 문제: 행사 1건당 사진 최대 2.4MB → Supabase 무료 DB 500MB 한도 빠르게 소진
- 기존 base64 데이터: 편집 후 저장 시 자동으로 Storage URL로 마이그레이션됩니다.
  Storage 설정이 안 된 경우에는 폴백으로 base64 그대로 DB에 저장됩니다 (기능은 유지됨).

---

## 3D 도면 기능 개발 로드맵

### 목적
클라이언트 제안용 3D 무대 도면을 SoundLog 안에서 생성 → SketchUp(.dae)으로 내보내기

### 구조
```
🎭 무대계산기 탭
  ├── [계산] 탭 (기존 + 평수 추가)
  └── [3D 도면] 탭 (신규)
        ├── 무대 크기 (계산기 연동 or 직접입력/평수)
        ├── 행사장 위치 (주소 → GPS / 사진 업로드 / 빈 공간)
        ├── 장비 배치 지시
        ├── 장비 .skp 라이브러리 (Supabase Storage)
        └── .dae 파일 생성 + 다운로드
```

### 개발 단계

| 단계 | 내용 | 상태 |
|---|---|---|
| 1단계 | 무대계산기에 평수(평) 표시 추가 | ⬜ |
| 2단계 | 무대계산기 안에 [3D 도면] 서브탭 틀 생성 | ⬜ |
| 3단계 | 무대 치수 입력 + 기본 .dae 파일 생성 (빈 공간) | ⬜ |
| 4단계 | 장비 박스+이름표 좌표 배치 → .dae 포함 | ⬜ |
| 5단계 | 장비 .skp 라이브러리 (Supabase Storage 업로드/다운로드) | ⬜ |
| 6단계 | 주소 → GPS → SketchUp 위성사진 연동 | ⬜ |
| 7단계 | 실내 도면/사진 업로드 → 바닥 배경 | ⬜ |

### 기술 메모
- **무대 단위**: 상판 1판 = 1.8m(가로) × 0.9m(세로), 1평 = 3.3058m²
- **내보내기 포맷**: Collada (.dae) — XML 기반, SketchUp 기본 지원
- **장비 표현**: 실제 .skp 모델 병합 불가 → 박스+이름표로 위치 표시, SketchUp에서 교체
- **장소 미입력 시**: 빈 공간(가로×세로 치수만) → GPS → 사진 순으로 대안
- **Supabase Storage 버킷**: `skp-library` (장비 .skp 파일 저장용, 별도 생성 필요)

---

## 트러스 .dae 조립 구현 현황 (2026-06-22 기준, v0622-30)

### 완성된 구조

트러스 설정 → .dae 내보내기 시 **직사각형 게이트 프레임** 형태로 조립됨:

```
[큐브]━━━━━[가로바]━━━━━[큐브]   ← 상단 (hTop)
  ┃                         ┃
[세로바]               [세로바]   ← 좌(vL) / 우(vR), 큐브 없음
  ┃                         ┃
[큐브]━━━━━[가로바]━━━━━[큐브]   ← 하단 (hBot)

전체 프레임이 iz2 = 무대높이(h) + 설치높이(elevation) 에 위치
```

### 핵심 함수 위치 (index.html)

| 함수 | 라인 | 역할 |
|---|---|---|
| `_buildTrussBar(sections, withCubes=true)` | ~9104 | 조각 배열 생성. 가로바=큐브포함, 세로바=큐브없음 |
| `emitBar(barSections, relX, relY, relZ, isVertical, barLabel, withCubes=true)` | ~9188 | 박스 XML 생성. 수평/수직 방향 처리 |
| `daeGenerate({w, d, h, stair, memo})` | ~9060 | 전체 .dae 파일 생성 |

### emitBar 좌표 계산 규칙

```js
// 수평바 조각: X 방향으로 배치
rx_fb = relX + pc.offset + pc.length / 2   // X 중심
rz_fb = relZ                                // Z 일정

// 수직바 조각: Z 방향으로 배치
rx_fb = relX                                // X 일정
rz_fb = relZ + pc.offset + pc.length / 2   // Z 중심 (offset+length/2)

// 박스 크기
ph  = isVertical ? pc.length : trussSpec   // 높이
bw2 = isVertical ? trussSpec : pc.length   // 가로 길이
```

### 배치 좌표 (daeGenerate 내부 ~9233)

```js
const cubeH = 0.22;
const iz2   = h + (t.elevation ?? 4.0);      // 프레임 하단 Z (무대높이+설치높이)
const hSpan = t.hTotalSpan || 0;             // 큐브 포함 가로 전체 길이
const vSpan = t.vTotalSpan || 0;             // 큐브 포함 세로 전체 높이

emitBar(hS, -hSpan/2, 0, cubeH/2,          false, 'hBot', true)   // 하단 가로바
emitBar(hS, -hSpan/2, 0, vSpan-cubeH/2,    false, 'hTop', true)   // 상단 가로바
emitBar(vS, -hSpan/2+cubeH/2, 0, cubeH,    true,  'vL',  false)   // 좌측 세로바
emitBar(vS,  hSpan/2-cubeH/2, 0, cubeH,    true,  'vR',  false)   // 우측 세로바
```

### 중요 설계 결정

- **3D 모델 임베드 사용 안 함**: SketchUp .dae 파일은 world position이 내장되어 좌표 충돌 발생 → 박스 폴백 전용
- `_embedDaeModel()` 함수는 현재 원본 상태 유지 (트러스에는 미사용)
- 가로바 박스에 `<rotate>0 1 0 90</rotate>` 적용으로 수평 방향 배치

### 버그 수정 이력

| 버전 | 수정 |
|---|---|
| v0622-21 | 세로바 Y→Z축, 큐브 중복 제거(`withCubes`), `iz2 = h + elevation` |
| v0622-22 | 가로바 `rotate 0 1 0 90`, 세로바 회전 제거 |
| v0622-23 | `_embedDaeModel` 위치 초기화 시도 (실패, 다음 버전에서 원복) |
| v0622-24 | 3D 모델 임베드 제거 → 박스 전용 |
| v0622-25 | 수직바 `rz_fb = relZ+offset+length/2` (중심점 수정, 겹침 해소) |
| v0622-26 | `elevation` 기본 4.0→0 (무대 위 착지), 재고 제약, `emitBar` 죽은코드 제거 |
| v0622-27 | 세로조각 `rz_fb=relZ+offset` (Z 바닥기준 타일링, v25 되돌림), 상·하바 Z 정렬 |
| v0622-28 | 트러스 창고 재고 기본 시드 (0.5/1/1.5m×4, 2m×6, 큐브×8) |
| v0622-29 | 트러스 X=0 무대 중앙 정렬, .dae 조각 임베드 재활성화 |
| v0622-30 | **.dae 모델 자동 정렬 완성** — bbox 평탄화 + 슬롯 fit matrix |

### .dae 모델 임베드 — 자동 정렬 방식 (v0622-30, 현재 동작)

실제 트러스 형상(.dae)을 슬롯에 끼우는 핵심 로직. SketchUp이 내보낸 .dae의
까다로운 특성을 코드가 자동 흡수한다.

| 함수 | 역할 |
|---|---|
| `_daeModelBBox(xmlText)` | 모델 전체 노드 트리(matrix·instance_node 체인)를 DOMParser로 평탄화 → 실제 월드 바운딩박스(미터) 계산. 단위(inch/mm) 자동 보정 |
| `_trussFitMatrix(bbox, opts)` | bbox를 슬롯에 중심 맞춰 끼우는 4x4 affine(row-major 16) 생성. 길이축 자동 감지(최대 extent) → 슬롯 길이축(수평=X/수직=Z)으로 회전 정렬 → 슬롯 크기로 스케일 |

**SketchUp .dae 모델의 함정 (실측으로 확인됨):**
- `<unit meter="0.0254">` — 단위가 **인치** (mm 아님)
- 컴포넌트 `<matrix>`에 **비균일 스케일**이 박혀 있음 (0.733, 1.25 등)
- 화면에서 원점에 놔도 파일 좌표는 **0,0,0 아님** (내부 좌표 보존)
- 모델 실제 길이 ≠ 라벨: 0.5m=H600(0.6m), 1m=H900, 1.5m=H1200, 2m=H1500
- → 위 모든 차이를 `_daeModelBBox`가 실측해 `_trussFitMatrix`가 슬롯에 정합시키므로
  단위·스케일·위치·라벨이 뭐든 자동으로 맞음

**모델 제작 주의:** 컴포넌트가 **축에 정렬**돼 있어야 함. 미세하게 기울어진 채
내보내면(예: 1.6° 회전 박힘) AABB 기준이라 기울기가 그대로 남음 → SketchUp에서
조각을 똑바로 세워 재내보내기 후 같은 타입에 교체 업로드.

**노드 출력 구조:**
```xml
<node><matrix>fit(16)</matrix><scale>unitScale ×3</scale>${embedded.sceneNodes}</node>
```
(fit은 미터 기준 → `<scale unitScale>`로 인치→미터 변환 후 적용되도록 순서 배치)

---

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
| 2026-06-21 | 행사일지 사진 저장 방식 변경: base64 → Supabase Storage URL |
| 2026-06-21 | `uploadPhotoToStorage`, `deletePhotosFromStorage` 함수 신설 |
| 2026-06-21 | 일지 삭제 시 Storage 파일도 함께 삭제, 이전 base64 데이터 자동 마이그레이션 |
| 2026-06-22 | 트러스 .dae 조립 구조 구현 — 직사각형 게이트 프레임 (가로바+큐브, 세로바) |
| 2026-06-22 | `_buildTrussBar(withCubes)`, `emitBar(isVertical, withCubes)` 구현 |
| 2026-06-22 | 3D 모델 임베드 제거 → 박스 전용 (좌표계 충돌 문제) |
| 2026-06-22 | 수직바 Z 중심점 수정 (겹침 해소, v0622-25) |
| 2026-06-22 | 트러스 무대 착지(elevation 0) + 창고 재고 제약 (v0622-26) |
| 2026-06-22 | 세로조각 Z 바닥기준 타일링으로 틈 해소 (v0622-27) |
| 2026-06-22 | 트러스 창고 재고 기본 시드 + 무대 중앙 정렬 (v0622-28~29) |
| 2026-06-22 | **트러스 .dae 실제 형상 자동 정렬 완성** — bbox 평탄화 + 슬롯 fit (v0622-30) |
