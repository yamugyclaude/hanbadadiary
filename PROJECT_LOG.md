# 한바다일지 (hanbadadiary) 진행 기록
생성일: 2026-07-03
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
