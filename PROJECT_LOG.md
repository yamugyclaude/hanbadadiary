# 한바다일지 (hanbadadiary) 진행 기록
생성일: 2026-07-03
---

## 2026-07-08 ⚠️ 조건부성공 — 접수함 관리자 탭 + 비밀번호 게이트 + 닫기버튼
### 배경
클라이언트가 제출한 행사진행의뢰서를 사장님이 확인할 방법이 없어서(Supabase 대시보드 직접
접속 외) 메인 앱 안에 조회 화면을 요청. 또 로그인화면의 진입 버튼 보호와 폼 사용성 개선(닫기
버튼) 요청도 함께 반영.

### 작업 내용
- **보안 설계 갈림길**: `event_requests`는 원래 SELECT가 전부 막혀있었음(고객끼리 응답을 못 보게).
  관리자 조회를 위해 열려면 (A) Supabase Edge Function으로 서버측에서만 조회(안전, 개발량 많음)
  vs (B) anon SELECT를 그냥 열어서 기존 앱과 같은 방식으로 빠르게 조회(빠름, 이 anon key를 아는
  외부인도 로그인 없이 전체 응답을 읽을 수 있는 리스크). **사장님이 (B) "빠르게, 리스크있음"을
  명시적으로 선택** → 비서가 Supabase MCP로 anon SELECT 정책 추가
- `index.html`에 관리자(`isAdmin`) 전용 "📥 접수함" nav 탭 신설 — `STORAGE_URL`/`STORAGE_KEY`(event_requests가
  있는 프로젝트, `SB_URL`/`SB_KEY`와는 다른 프로젝트임에 주의)로 최신순 목록 조회, 카드 클릭 시
  기존 장비 상세모달 패턴 재사용해 18문항 전체 + 첨부파일 표시
- 로그인화면 "행사진행의뢰서" 버튼에 비밀번호(2375) 게이트 추가(`openEventRequestForm()`) — 외부
  클라이언트에게 공유하는 직접 링크(`event-request/`) 자체는 그대로 열려있고, 로그인화면에서의
  진입 경로만 보호
- `event-request/index.html` 제출폼 하단 + 완료화면에 "닫기"(`window.close()`) 버튼 추가

### 검증 (auditor, sonnet)
- curl 실증: anon key로 `event_requests` SELECT → 200 실데이터 반환(개방 확인), INSERT 정상
  동작, UPDATE/DELETE 시도는 0건 매칭으로 실제 변조 안 됨(재조회로 확증) — 사장님이 승인한
  "SELECT만 개방" 의도와 실제 구현 일치
- 코드 검토: 비밀번호 게이트 로직, isAdmin 탭 토글, STORAGE_URL/KEY 정확한 사용, 닫기버튼 연결
  전부 확인
- ⚠️ 최초 감사 시 CHANGELOG.md/PROJECT_LOG.md 미반영 지적받아 이 기록으로 보완(재발 — 배포 후
  즉시 문서화 습관화 필요)

### 결과
- **작업 완료** — ⚠️ 조건부통과 → 문서화 보완으로 해결
- 파일: `index.html`(접수함 탭, 비밀번호 게이트), `event-request/index.html`(닫기 버튼)
- 커밋: `c091167`(닫기버튼) → `a06b656`(접수함탭) → `11d98c7`(비밀번호게이트)
- 브랜치: `claude/content-analysis-v9gjwm` (main 병합·배포 대기 중)

### 다음 예정
- 🛠️ 텔레그램 알림: 클라이언트가 폼을 **제출**하면 텔레그램으로 알림 — Supabase Edge Function이
  봇 토큰을 서버측 비밀로 보관하고 Telegram API 호출하는 방식으로 설계(클라이언트 코드에 토큰
  노출 안 시킴). 사장님이 Bot Token 전달 완료, Chat ID 대기 중

---

## 2026-07-08 ✅ 성공 — 로그인 화면 "행사진행의뢰서" 버튼 + 독립 페이지 신규 추가
### 배경
사장님이 기존 카테고리(탭)와 별개로, 로그인 화면 자체에 "행사진행의뢰서" 진입 버튼을 새로 만들어
독립 페이지로 이동하도록 요청. 참고용으로 업로드한 PDF(음향/무대/조명 행사 진행 의뢰서 양식)는
이번 작업에서는 내용 분석까지만 하고, 실제 폼 내용은 사장님이 이후 별도로 지시할 예정.

### 작업 내용
- `index.html` `#loginScreen` 안, 기존 `.checklist-open-btn`(📋 챙겨야할 물품체크리스트) 바로 아래에
  같은 클래스를 재사용한 `📄 행사진행의뢰서` 버튼 추가. `onclick="window.open('./event-request/', '_blank')"`로
  로그인 화면은 그대로 유지한 채 새 탭에서 열리도록 함 (사장님 지정: 새 탭 방식)
- 신규 파일 `event-request/index.html` 생성 — 기존 `thought-organizer/`와 같은 "완전 독립 페이지" 패턴
  (메인 앱 로그인·CSS·JS와 무관, 자체 완결 HTML). 지금은 제목과 "준비 중입니다" placeholder만 있는 뼈대

### 결과
- **작업 완료** — builder(sonnet)가 구현, auditor(sonnet)가 diff 기반 검증 완료 (✅ 통과: 버튼 1줄 추가,
  기존 로그인 요소 무손상, 경로/파일 위치 일치, 독립 HTML 완결성 확인)
- 파일: `index.html` (1594번째 줄 부근), `event-request/index.html` (신규)
- 브랜치: `claude/content-analysis-v9gjwm` (main 미병합, 버전 자동증가는 main push 시에만 동작하므로 아직 버전 미반영)

### 다음 예정
- 🛠️ ~~사장님이 제공할 실제 "행사진행의뢰서" 폼 내용으로 `event-request/index.html` 채우기~~ → 완료 (아래 항목 참고)

---

## 2026-07-08 ✅ 성공 — 행사진행의뢰서 18문항 웹폼 완성 + Supabase 연동
### 배경
사장님이 업로드한 PDF("행사 진행 의뢰서" — 음향/무대/조명 서비스 문의 양식)를 구글폼처럼 실제
작동하는 웹폼으로 만들고, 클라이언트에게 링크를 보내 작성받은 데이터를 나중에 활용하기로 함.

### 작업 내용
- planner(sonnet)가 폼 UX(단일 스크롤 6섹션) + DB 스키마 + RLS 설계 → 사장님 승인
- 비서가 Supabase MCP로 `event_requests` 테이블 생성 (프로젝트: `poxafvsqxvcaewduhvxt`, 메인 앱 사진 Storage와
  같은 프로젝트, 기존 `soundlogs`가 있는 DB 프로젝트와는 별개). RLS: anon role에 **INSERT만 허용**
  (`with check(true)`), SELECT/UPDATE/DELETE 정책 없음 → 클라이언트가 서로의 제출 내용을 못 봄
- builder(sonnet)가 `event-request/index.html`을 원본 PDF 문구 그대로 18문항 폼으로 재작성.
  필수/선택 표시, 체크박스 "기타" 선택 시 서술 입력창 노출, honeypot hidden input(값 있으면 조용히
  제출 무시 — 봇 차단), 제출 성공 시 감사 화면으로 전환. 메인 앱 로그인/CSS/JS와 완전 독립

### 검증 (auditor, sonnet)
- curl로 anon key 사용해 실제 확인: `GET .../event_requests` → `[]` (SELECT 완전 차단),
  `POST` 필수 컬럼 채운 테스트 insert → HTTP 201 성공, 직후 재조회도 `[]` (RLS 실증 확인)
- payload 21개 키 = 테이블 컬럼 21개(id/created_at 제외) 1:1 일치, 필수 검증 로직이 13개 필수
  문항 모두 커버, 메인 앱 파일 참조 없음(완전 독립) 확인
- ⚠️ 감사 과정에서 테스트용 더미 행(`contact_name="감사테스트"`)이 `event_requests`에 남음 —
  SELECT/DELETE가 RLS로 막혀 있어 anon key로는 삭제 불가, Supabase 대시보드에서 직접 삭제 필요
  (사장님 확인 대기)

### 결과
- **작업 완료** — ⚠️ 조건부통과(문서화 누락 지적받아 이 기록으로 보완)
- 파일: `event-request/index.html` (재작성)
- 커밋: `b065e27`, 브랜치: `claude/content-analysis-v9gjwm` (main 미병합, 배포는 사장님 지시 대기)

### 다음 예정
- 🛠️ main 병합·배포 여부 사장님 확인
- 🛠️ 감사 중 남은 테스트 더미 행 삭제 여부 확인
- 🛠️ 제출된 데이터로 무엇을 할지(관리자 조회 화면 등)는 사장님이 차후 지시 예정

---

## 2026-07-05 ✅ 성공 — 클라우드 저장 거짓 경보 수정
### 배경
사용자가 새 행사일지 저장 시 "저장완료, 클라우드 실패" 토스트를 봄. 라이브 Supabase DB를
REST API로 직접 조회(id로)해서 확인한 결과, **실제로는 클라우드에 정상 저장돼 있었음** (진짜
실패가 아니라 거짓 경보였음).

### 원인
`saveAndSync()`(index.html)의 `Promise.race([cloudWork, timeout(20000)])` 구조에서
20초 타임아웃이 이기면 화면엔 "클라우드 실패"라고 뜨지만, `cloudWork`(실제 fetch)는
취소되지 않고 백그라운드에서 계속 진행됨(AbortController 없음). 이번 케이스처럼 네트워크가
20초를 살짝 넘겼지만 결국 성공한 "늦은 성공"을 코드가 전혀 추적하지 않고 `_syncFailed = true`로
영구 고정해버림.

### 수정
- `cloudWork`를 try 블록 밖에서 `let cloudWork;`로 선언 → catch에서도 접근 가능
- catch에서 `e.message === 'CLOUD_TIMEOUT'`인 경우에만 `cloudWork.then()`으로 늦은 성공을
  지켜보다가, 성공하면 `_syncFailed` 해제 + `persistLogs()` + (목록 화면이면) `renderList()` +
  "☁️ 늦게 도착: 클라우드 저장 완료" 토스트로 정정
- 20초 타임아웃 자체(사용자에게 20초 안엔 반드시 결과를 보여주는 설계)는 그대로 유지, 그 이후
  늦게 성공하는 경우만 추가로 추적
- 파일: index.html (saveAndSync 함수, `cloudWork` 선언 + catch 블록)
- 커밋: `c30b09a`, main 병합: `121d44e`

---

## 2026-07-03 ✅ 성공
### 작업 내용
- 행사일지 저장 메시지 안내 버그 수정

### 결과
- **문제 해결 완료**
- showToast() 함수: 타이머 관리 개선 (clearTimeout, duration 파라미터 추가)
- saveAndSync() 함수: 메시지 표시 시간을 5초로 연장
- 저장 중... 메시지가 사진 업로드/동기화 완료까지 표시됨

### 기술 상세
1. showToast() 함수 개선 (6760-6767줄):
   ```javascript
   let toastTimeout;
   function showToast(msg, duration = 3500) {
     const el = document.getElementById('toast');
     clearTimeout(toastTimeout);  // 타이머 충돌 방지
     el.textContent = msg;
     el.classList.add('show');
     toastTimeout = setTimeout(() => el.classList.remove('show'), duration);
   }
   ```

2. saveAndSync() 함수 (6839줄):
   ```javascript
   showToast('저장 중…', 5000);  // 5초로 연장
   ```

### 배운 것
- Toast 메시지의 타이머가 비동기 작업 시간보다 짧으면 메시지가 사라진 것처럼 보임
- duration 파라미터로 메시지별 표시 시간을 유연하게 조정 가능

### 배포 이력
- 버전: v0703-59 → v0703-60
- 브랜치: `claude/korean-greeting-6cbh25` → main으로 머지
- 커밋: 31b9bd5 (코드 수정), e39be64 (문서 기록), b43e643 (CHANGELOG 기록)
- 배포 일시: 2026-07-03
- 상태: 배포 준비 완료

---

## 2026-07-03 (2차) ⚠️ 오진 4회 → 감사 후 재진단 성공
### 작업 내용
- 사용자가 "핸드폰에서 저장중 메시지가 안 보인다"고 재보고 → 이어서 2차례 더 수정 시도(duration 추가, CSS 위치/색상 변경) → 여전히 해결 안 됨 → 사용자가 감사실장 호출 요청

### 무엇이 잘못됐었나 (반드시 기억할 것)
1. **v0703-57 (duration 누락 진단)**: `showToast(msg, duration=3500)`에 이미 기본값이 있었는데 "duration 생략이 원인"이라고 오진. **코드를 안 읽고 추측만으로 패치함.**
2. **v0703-58 (CSS 위치 변경)**: 근본 원인 확인 없이 미관만 개선. 오히려 `bottom:20px`로 내려서 모바일 키보드에 가려질 위험을 새로 만듦 (회귀).
3. **v0703-60 (getFormData null 체크)**: **자기모순 진단.** getFormData()가 null이면애초에 `localStorage.setItem`도 실행 안 되는데, 사용자는 "데이터는 기록됨"이라고 말했음. 이 모순을 눈치채지 못하고 그냥 방어 코드만 추가함.

### 진짜 원인 (감사실장 auditor 서브에이전트 독립 검증으로 발견)
- **`updateTitle()`의 무방비 DOM 접근이 예외를 던져 `saveAndSync()`를 조기 중단시킴.** `localStorage.setItem`(저장 완료) 다음 줄에서 호출되는데, try/catch 밖이라 예외가 나면 그 다음 줄의 `showToast('저장 중…')`에 영원히 도달 못함. "데이터는 저장되는데 메시지가 안 뜬다"는 증상과 정확히 일치.
- **iOS 홈스크린 캐싱**: 서비스워커/캐시 무효화 장치가 전혀 없어서, 4번의 수정이 사용자 폰에 아예 반영되지 않았을 가능성. "고쳐도 고쳐도 재발"의 유력 원인.

### 수정 (v0703-61)
1. `updateTitle()` — 옵셔널 체이닝 적용, 예외 발생 원천 차단
2. `<head>`에 캐시 방지 메타태그 3줄 추가
3. `.toast` 위치를 하단→상단(16px)으로 변경 — 키보드 가림 회귀 해소
4. 디버그 `console.log` 제거

### 배운 것 / 반복하면 안 되는 실수
- **"토스트가 안 뜬다"는 신고를 받으면 먼저 showToast() 자체가 아니라, 그걸 호출하기 *직전*의 코드 흐름에서 예외가 나서 호출 자체가 안 됐을 가능성부터 확인할 것.** 특히 try/catch 밖에 있는 동기 함수 호출들을 의심.
- **사용자가 말한 사실("데이터는 저장됨")과 내 진단이 모순되지 않는지 항상 교차 검증할 것.** v0703-60처럼 모순된 진단을 그대로 밀어붙이면 안 됨.
- **반복되는 버그(3회 이상 재발)는 코드 문제가 아니라 배포/캐싱 문제일 가능성을 반드시 의심할 것.** 이 프로젝트는 PWA 유사 환경(iOS 홈스크린)인데 서비스워커가 없어 캐시 무효화가 안 됨 — 구조적 위험.
- **추측으로 패치하지 말고, 관련 함수 전체를 직접 읽고 실행 순서를 추적한 뒤 수정할 것.** 감사실장이 지적한 것처럼 1~4차 수정 모두 "표면 증상만 보고 패치"한 게 문제였음.

### 배포 이력
- 버전: v0703-60 → v0703-61
- 커밋: 5차 수정 (updateTitle 방어코드, 캐시 메타태그, 토스트 위치 변경, 디버그 로그 제거)
- 상태: 배포 예정

---

## 2026-07-03 (3차) ⚠️ 사후 기록 — 행사일지 삭제 로직 3연속 재수정 (감사 호출 누락)
### 무엇
- v0703-71(`f497d96`) 삭제 재발 근본 수정 → v0703-72(`827eb10`) 삭제 로직 재설계 → v0703-73(`ebef06b`) 버전 번호 근본 수정. 같은 날 삭제 관련 "근본 수정"이 3번 반복됨.
- 오진 그룹(위 2차 기록)과 같은 재발 패턴이지만, 이때는 감사실장을 부르지 않고 넘어감 — 이번 감사(2026-07-05)에서 뒤늦게 발견.
### 배운 것
- 동일 기능을 하루에 2회 이상 재수정하면 감사실장을 자동 호출한다 (CLAUDE.md에 규칙 추가, 2026-07-05).

---

## 2026-07-05 목록 지연 표시 + 장비 저장 팝업 반응성 수정
- v0705-02(`03cbc1e`) 행사일지 목록: 조회 모드에서도 백그라운드 재조회 허용
- v0705-03(`615d32b`) 장비 저장/추가 팝업: 클라우드 await 전에 즉시 닫기 + 20초 타임아웃 (기존 삭제·저장 로직과 동일 패턴 적용)

### 감사 결과 요약 (2026-07-05, 사장 요청으로 토큰 효율성 점검)
- 오진 4회(v0703-56~61)·삭제 3연속 재수정(v0703-71~73) 모두 **모델 크기 문제가 아니라 "코드 안 읽고 추측 패치"가 원인**.
- CHANGELOG·PROJECT_LOG가 v0703-73 이후 갱신 안 되어 있던 문서 공백을 이번에 메움.
- 재발 방지 규칙 4건을 CLAUDE.md에 추가: 재발 2회 시 감사 자동 호출 / 선-조사 게이트 / 배포 후 즉시 문서화 / 보고 간결화.

---

## 2026-07-05 (2차) 장비 저장 팝업 반응 지연 잔여 수정 + base64 사진 백그라운드 정리
### 무엇
- v0705-03(`615d32b`)이 `switchEqCat`/`closeEquipModal`은 로컬 반영 뒤로 옮겼지만, `_migrateEquipPhotos`
  (사진 Storage 업로드)는 여전히 그보다 앞서 await 하고 있어 사진이 있는 장비는 여전히 팝업이 늦게 닫힘.
- `saveEquipEdit`/`saveEquipAdd`(index.html): 사진 업로드도 로컬 반영 이후, 클라우드 동기화와 함께
  20초 타임아웃 안에서 순서대로(사진 업로드 → `_syncEquipmentCloud`) 처리하도록 수정.
- `migrateOldLogPhotos()` 신규 추가: `autoLoadAll()` 완료 5초 후 백그라운드로 1회 실행, `logs` 중
  base64 사진이 남은 항목만 걸러 `uploadPhotoToStorage`로 업로드 → URL 교체 → `sbUpsertLog`로 클라우드
  반영 → 전체 완료 후 `persistLogs()`. 실패한 로그는 base64 그대로 유지(유실 없음), 로그 간 150ms 지연.

### 배운 것
- "로컬 반영을 먼저"라는 수정이 화면 갱신 함수 호출만 옮기고, 그 앞에 남은 다른 await(사진 업로드 등)를
  놓치면 같은 증상이 재발한다 — 관련 함수 전체의 실행 순서를 끝까지 추적해야 함.

### 배포 이력
- 커밋: `e399b61`
- 상태: 브랜치 `claude/gamsasiljang-ls5xvg` push 완료, main 병합 시 버전 자동 부여 예정

---

## 2026-07-05 (3차) 장비 수정저장 무반응 근본 수정 — catch 없는 try가 진짜 원인
### 무엇이 잘못됐었나
- `saveEquipEdit()`(6202~6232행)의 `localStorage.setItem('equipmentData', ...)`가 **catch 없는 try
  블록 안**에 있었음. 이 줄에서 예외(용량 초과 `QuotaExceededError` 등)가 나면 그 아래
  `switchEqCat`/`closeEquipModal`/`showToast`가 전부 실행되지 않고 함수가 조용히 멈춤 — "수정저장
  눌러도 팝업이 안 닫히고 반응 없다"는 신고와 정확히 일치.
- `persistLogs()`(soundlogs 저장)는 이미 이 위험을 알고 try/catch로 방어하고 있었는데,
  `equipmentData`를 저장하는 13곳은 전부 이 방어가 누락돼 있었음. 2차 수정(await 순서 조정)은
  이 근본 원인과 무관한 다른 문제를 고친 것이었음.

### 수정
- `persistEquipment()` 헬퍼 추가(`persistLogs()`와 동일 패턴, try/catch로 예외 흡수) — 13곳 전부
  `localStorage.setItem('equipmentData', ...)` 직접 호출을 `persistEquipment()` 호출로 교체.
- `migrateOldEquipPhotos()` 신규 추가(`migrateOldLogPhotos()`와 동일 구조): `autoLoadAll()` 완료
  7초 후 백그라운드 1회 실행, `equipmentData`의 모든 카테고리 중 base64 사진이 남은 장비만 걸러
  `uploadEquipPhoto`로 업로드 → URL 교체 → `_syncEquipmentCloud`로 클라우드 반영 → 완료 후
  `persistEquipment()`. 실패한 사진은 base64 그대로 유지(유실 없음), 항목 간 150ms 지연.

### 배운 것
- "저장 후 화면 반영이 안 된다"는 신고는 순서 문제만이 아니라, **저장 자체가 예외로 조용히 실패**할
  가능성부터 먼저 확인해야 한다. 같은 함수 계열(persistLogs) 안에 이미 정답 패턴이 있었는데
  equipmentData 쪽만 누락된 것 — 유사 코드 전체를 grep으로 재점검하는 습관이 필요.

### 배포 이력
- 브랜치: `claude/gamsasiljang-ls5xvg` → main 병합 예정

---

## 2026-07-05 (4차) 호버 미리보기가 실제 모달 위에 겹쳐 남는 문제 수정
### 무엇이 잘못됐었나
- 카드에 마우스를 올리면 뜨는 요약 툴팁(`#hoverPreview`, z-index 8000)을 닫는 `hideHoverPreview()`는
  `onmouseleave`에만 걸려 있었음. 카드를 클릭해 실제 상세 모달을 여는 `openLog`/`openEquipView`/
  `openAlbaWorkerView`/`openAlbaSchedEdit`/`openTaskModal`에는 미리보기를 닫는 코드가 전혀 없어서,
  일부 환경(넓은 화면)에서는 미리보기가 모달 위에 그대로 겹쳐 보였음.

### 수정
- `dismissHoverPreview()` 신규 추가(index.html:6407 부근) — 지연 없이 즉시 닫는 헬퍼. 기존
  `hideHoverPreview()`(80ms+120ms 지연)는 그대로 유지.
- 5개 모달 오픈 함수(`openLog` 3738행, `openEquipView` 5912행, `openAlbaWorkerView` 5141행,
  `openAlbaSchedEdit` 5407행, `openTaskModal` 7250행) 맨 첫 줄에 `dismissHoverPreview();` 추가.

### 배포 이력
- 커밋: `1139522`, main 병합 `d19f983`

---

## 2026-07-05 (5차) "저장완료, 클라우드 실패" 후 확인 불가 문제 수정
### 무엇이 잘못됐었나
- `sbUpsertLog()`(index.html:7014)가 PATCH 응답을 `res.json()`으로 이미 읽어놓고, PATCH 자체가
  실패한 경우 `if (!res.ok) throw new Error(await res.text())`에서 **같은 Response의 body를 또
  읽으려 해서** "body already read" 예외가 진짜 오류를 덮어버림. 그래서 콘솔에서도 원인 파악 불가.
- 또한 클라우드 저장 실패 시 로그에 아무 표시도 남지 않아, 사용자가 나중에 어떤 일지가
  동기화 안 됐는지 확인할 방법이 없었음.
- `loadLogsFromCloud()`가 클라우드 목록으로 `logs`를 통째로 교체해서, 클라우드 저장에 실패한
  로컬 전용 일지가 다음 클라우드 재조회 때 사라질 위험이 있었음.

### 수정
- `sbUpsertLog()`: PATCH 응답 body를 `res.text()`로 한 번만 읽고 JSON 파싱 시도. 실패 메시지는
  읽어둔 텍스트를 그대로 사용(index.html:7014-7027).
- `saveAndSync()`: 클라우드 저장 성공 시 `log._syncFailed` 삭제, 실패 시 `true`로 세팅 후
  `persistLogs()` 호출(index.html:7086-7101).
- `renderList()`: `l._syncFailed`인 카드에 `⚠ 미동기화` 배지 표시 + `.log-card-unsynced` CSS
  추가(index.html:3795, 163).
- `loadLogsFromCloud()`: 클라우드 목록으로 덮어쓰지 않고, 클라우드에 없으면서 `_syncFailed`인
  로컬 로그는 보존하는 병합 방식으로 변경(index.html:7934-7938).

### 배운 것
- Response body는 한 번만 읽을 수 있다는 fetch API 제약을 놓치면, 에러 핸들링 코드 자체가
  새로운 예외를 만들어 원인을 가리는 역설이 발생한다.

### 배포 이력
- 커밋: `52dec9d`, main 병합 `a8197f6`

---

## 2026-07-05 (6차) "저장 실패" 추측 판정을 AbortController 기반 실제 취소로 근본 수정
### 무엇이 잘못됐었나
- 직전 커밋 `c30b09a`는 `Promise.race([cloudWork, timeout(20000)])`에서 타임아웃이 이기면 일단
  "실패"로 표시해두고, 방치된 `cloudWork`가 나중에 실제로 성공하면 `_syncFailed`를 정정하는 방식이었다.
- 사장 지적: 이 방식 자체가 "추측으로 먼저 실패를 알리고 나중에 정정"하는 구조라 마음에 들지 않는다 —
  판정을 미룰 수 있을 때까지 미뤄서 처음부터 실제 결과에만 기반한 정확한 판정만 내려야 한다.
- 근본 원인: `Promise.race`가 타임아웃 쪽을 택해도 실제 `fetch` 요청(`cloudWork` 내부)은 **취소되지
  않고** 백그라운드에서 계속 진행됐음. 이 fetch를 진짜로 취소할 방법이 없어서 사후 정정 로직이
  필요했던 것.

### 수정
- `uploadPhotoToStorage(logId, type, idx, base64, signal)`(index.html:4254): `signal` 파라미터
  추가, `fetch()` 옵션에 전달.
- `sbUpsertLog(log, signal)`(index.html:7014): PATCH/POST 두 `fetch()` 모두에 `signal` 전달,
  AbortError는 그대로 상위로 전파(삼키지 않음).
- `saveAndSync()`(index.html:7050-7103): `Promise.race` + 방치된 `cloudWork` IIFE 구조를 제거하고
  `AbortController`(60초 타임아웃)를 만들어 사진 업로드 루프와 `sbUpsertLog` 호출에 `signal`로
  전달. 60초를 넘기면 `abort()`가 실제로 요청을 취소하므로, 이후 발생하는 `AbortError`만 "클라우드
  응답 없음" 문구를 띄운다. `c30b09a`가 추가했던 "늦게 도착: 클라우드 저장 완료" 사후 정정 블록은
  완전히 삭제 — 더 이상 필요 없음(판정이 처음부터 정확하기 때문).
- "저장 중…" 토스트도 60초로 연장해 취소 대기 시간 동안 화면이 멈춘 것처럼 보이지 않게 함.
- "실패"라는 문구 자체는 사장 요청대로 유지, 표시 조건만 추측 → 실제 결과로 변경.

### 배운 것
- 타임아웃으로 "포기"만 하고 실제 작업을 취소하지 않으면, 그 작업은 백그라운드에서 계속 진행되다
  나중에 성공해서 "거짓 실패 경보"를 만든다. `AbortController`로 진짜 취소가 가능한 API(fetch)라면
  방어적 사후 정정 로직 대신 애초에 취소를 걸어 판정 시점을 정확하게 만드는 게 근본 해법.

### 배포 이력
- 커밋: `9d6b2fe`, main 병합 예정
