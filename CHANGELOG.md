# CHANGELOG — SoundLog (한바다 작업일지)

변경사항은 배포할 때마다 이 파일에 기록합니다.

---

## [2026-05-28] — 3.5톤 차량 데이터 저장 버그 수정

**커밋**: `(pending)`

### 수정
- **3.5톤 마이티 데이터 클라우드 저장 안 되는 문제 수정**
  - Supabase `vehicle_data` 테이블의 `v35` 컬럼 의존성 제거
  - v15 + v35 데이터를 `v15` 컬럼 하나에 합쳐서 저장 (`_format: 'combined'` 마커)
  - 구버전 데이터 하위 호환 유지
- **정비 기록 저장 시 자동 클라우드 동기화 추가**
  - 기존: 정비 기록 저장이 로컬(localStorage)에만 저장됨
  - 수정: `saveMaintModal()` / `deleteMaintenance()` 호출 시 `_syncVehicleCloud()` 자동 실행
  - 토스트 메시지에 ☁️ 아이콘 추가
- `_syncVehicleCloud()` — 조용한 백그라운드 클라우드 동기화 함수 신설
- `_applyVehicleCloudData()` — 클라우드 데이터 적용 (combined/legacy 둘 다 지원)

---

## [2026-05-26] — 행사일지 폼 UI 대대적 개편

**커밋**: `ec08104`

### 수정
- **콘솔/스피커 입력 간소화**
  - 모델 그리드 제거 → 브랜드 선택 후 텍스트 입력칸 1개만 표시
  - `f_consoleModel` / `f_speakerModel` 단일 텍스트 필드로 저장
- **섹션 순서 변경**
  - 모니터 스피커 세팅 → 투입 장비 앞으로 이동
  - 전기 → 이슈&해결 앞으로 이동
- **내부 메모 텍스트 영역 3배 확장** (`min-height: 246px`)
- **사진 업로드 기능 추가** (4장씩)
  - 음향장비 섹션에 사진 4장 업로드 그리드 추가
  - 무대설치 섹션에 사진 4장 업로드 그리드 추가
  - Base64 저장, 최대 800px 리사이즈, JPEG 0.7 압축
  - `soundPhotos` / `stagePhotos` 배열로 일지 데이터에 저장

---

## [2026-05-26] — 멀티기기 동기화 3가지 수정

**커밋**: `472b5ff`

### 수정
- **사용자 계정 클라우드 동기화**
  - `syncUsersToCloud()` / `loadUsersFromCloud()` 함수 추가
  - Supabase `vehicle_data` 테이블의 `id='sl_users'` 행에 사용자 배열 저장 (신규 테이블 불필요)
  - `doLogin`: 로컬 미발견 시 자동으로 클라우드 조회 후 재시도 (다른 기기에서 로그인 가능)
  - `doRegister` / `deleteUser`: 변경 시 즉시 클라우드 반영
  - `autoLoadAll`: 로그인 직후 사용자 목록 최신화
  - `initRealtime`: `sl_users` 행 변경 실시간 수신

- **차량 데이터 Realtime 구독 추가**
  - `vehicle_data` 테이블을 WebSocket 구독 목록에 추가
  - 다른 기기에서 차량 정보 저장 시 수동 새로고침 없이 즉시 반영

- **업무 저장 API 최적화**
  - `syncOneTaskToCloud(task, type)` 함수 추가
  - 업무 1개 변경(저장·상태변경) 시 해당 건만 Supabase upsert
  - `saveTasksLocal()`에서 전체 업무 일괄 업로드 제거

---

## [이전] — 초기 구축

- 행사일지, 창고/사무실/대표지시 업무, 차량 관리 기능
- Supabase 연동 (soundlogs, tasks, vehicle_data, access_logs)
- 로그인/회원가입 시스템 (관리자 승인 코드: 6293)
- WebSocket Realtime (soundlogs, tasks)
- 다크/라이트/파스텔 테마 선택
- GitHub Pages 배포
