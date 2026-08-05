# 한바다일지 (hanbadadiary) 진행 기록
생성일: 2026-07-03
---

## 2026-08-05 ✅ 성공 — 정기 점검: 라이브 비밀번호 노출 차단 + 백업 체계 신설
### 배경
사장님: "점검좀 해봐" → 이어서 "자료백업은 어떻게 해야하는지 그것도 좀 봐줘" → "둘다 진행해".

### 발견 1 — 관리자 비밀번호가 라이브에서 그대로 읽혔다 (curl 실증)
`deploy.yml`의 `upload-pages-artifact` 가 `path: '.'` 로 **저장소 전체**를 Pages에 올리고, `.nojekyll` 때문에 `.md`가 그대로 서빙됐다.

| URL | 응답 |
|---|---|
| `/README.md` | 200 — `id=hanbada / pw=2375`, 수정·삭제 암호 |
| `/PROJECT_LOG.md` | 200 |
| `/CHANGELOG.md` | 200 |
| `/.claude/settings.json` | 200 |

`event_requests`의 RLS가 anon에게 전면 개방된 상태(2026-07-08 사장님 승인)와 겹치면, 앱의 `2375` prompt 게이트가 **사실상 무력화**된 상태였다.

**조치**: `_site/`에 웹 자산만 복사해 배포하도록 변경 + `.md`/`.claude` 혼입 시 배포 중단 가드. 문서의 평문 비밀번호 마스킹.

### 발견 2 — 백업 수단이 전혀 없었다
데이터 위치를 전수 조사한 결과(실측): `vehicle_data` 88행 2.0MB, `soundlogs` 23행 6.6MB, `tasks` 99행 60KB, `access_logs` 0행, `event_requests` 0행, Storage `skp-library/models` 25개 41MB. 여기에 **클라우드 사본이 없는 로컬 전용 키 3개**(`trussInventory`, `lib3dCustomTypes`, `lib3dHiddenTypes`)가 있어 브라우저 캐시를 지우면 그냥 소실되는 상태였다.

`a.download`가 4곳 있었지만 전부 일지 MD 내보내기·SketchUp `.dae`·첨부파일이고 **데이터 백업이 아니었다.** 복구 수단도 없었다.

**조치**: `backup.yml` 신설(매일 JSON + 주 1회 3D 모델, artifact 전용 보관) + 앱 관리자 모달에 💾 백업 탭(백업/복구).

### ⚠️ 반복 방지 관점 — "성공한 척하는 실패"를 3번 잡았다
이번에 커밋 전에 걸러낸 것들. 전부 **실패했는데 성공으로 표시되는** 유형이다.

1. **에러 응답이 3D 모델 파일로 둔갑** — 다운로드 curl에 `--fail`이 없어 404 본문(88바이트 JSON)이 `.dae`로 저장됐다. 파일이 존재하고 0바이트도 아니라 개수 검증·빈파일 검증을 **둘 다 통과**했다. → `--fail` + `.dae` 첫 바이트가 `<`인지 검사.
2. **3D 백업이 한 번도 안 돌 뻔함** — cron 두 개(`0 18 * * *`, `0 18 * * 0`)가 일요일에 겹쳤다. GitHub이 겹치는 cron을 한 번만 트리거하면 한쪽 job은 영영 안 돈다. **확인할 수 없는 동작에 의존하고 있었다.** → cron 하나로 줄이고 job 안에서 요일을 직접 판정.
3. **복구가 동작하는지 아무도 몰랐음** — `applyRestore`가 `Prefer: resolution=merge-duplicates`를 썼는데 이 앱 전체에서 그 커밋이 유일한 사용처였다(`grep -c` → 1). PK/unique 제약이 있어야 동작하는데 anon 키로는 스키마 조회가 막혀 있어(`Only the service_role API key...`) 확인 불가였다. 드러나는 시점은 진짜 복구가 필요한 순간이었을 것. → 앱이 이미 쓰는 `PATCH ?id=eq.{id}` → 빈 배열이면 `POST` 패턴으로 교체(읽기 전용 PATCH로 200/배열1건, 없는 id면 `[]` 실증).

### ⚠️ 비서실장 자체 실수 — 문서를 파일명으로 찍어 확인해서 1개를 놓쳤다
마스킹 대상을 `README`·`CHANGELOG`·`PROJECT_LOG` 3개로 지목했는데, **`PROJECTS.md`에도 평문 `2375`가 있었다**(감사실장이 발견). Pages에선 빠지지만 저장소가 public이라 `raw.githubusercontent.com`으로 200 노출되는 걸 실증 확인했다.
→ **앞으로 이런 전수 작업은 파일명을 열거하지 말고 저장소 전체 검색(`grep -rn --include="*.md"`)으로 범위를 잡는다.** 재확인도 같은 방식으로 한다.

### 확인 안 된 것 (남은 위험)
- `backup.yml`이 **실제 러너에서 끝까지 도는 것은 아직 검증 안 됐다.** cron·`workflow_dispatch` 모두 워크플로가 기본 브랜치에 있어야 발화하는데 아직 main 병합 전이다. **main 병합 직후 수동 실행(workflow_dispatch)으로 1회 실증할 것.**
- 복구 전체 실행은 운영 데이터가 바뀌므로 하지 않았다. 최초 1회는 사장님 입회 하에 확인 권장.
- 마스킹은 git 히스토리를 지우지 않는다. 과거 커밋의 `2375`는 여전히 조회 가능 → 진짜 무효화는 비밀번호 교체뿐(사장님 판단 대기).
- 옛 비밀번호 `6293`은 CHANGELOG 5곳에 남겼다. `index.html` 전체 grep에서 미발견돼 폐기값임을 확인했고, 이력 기록으로서의 가치가 있어 그대로 뒀다.

---

## 2026-07-27 ✅ 성공 — 알바관리 먹통 버그 3건 수정 (배준 카드 + 클라우드 저장 누락 + 모바일 +N개)
### 배경
사장님: "대표지시란에서 알바부분 점검해봐. 안되는 기능들이 있어" → 이어서 "배준 알바팝업을
클릭해도 안들어가진다".

### ⚠️ 반복 방지 관점 — 18일간 방치된 기지(旣知) 버그
2026-07-09 로그의 "참고 (범위 밖, 조치 안 함)" 항목에 **이번 A번 버그가 이미 정확히 기록**돼
있었다(`b.date.localeCompare(a.date)`). "사장님께 별도 보고 예정"으로 남긴 뒤 실제로 조치되지
않아, 사장님이 직접 증상을 겪고 다시 지시할 때까지 18일이 걸렸다.
→ **앞으로 조사 중 발견한 기지 버그는 "범위 밖"으로 남기지 말고, 최소한 사장님께 즉시 보고하고
   조치 여부를 그 자리에서 확정한다.**

### 진단 (추측 아님 — 라이브 데이터로 실증)
`vehicle_data.id='alba'` 를 직접 조회해 조건 일치를 확인:

| 알바 | 스케줄 | `date` 필드 없는 건수 | 카드 클릭 |
|---|---|---|---|
| 배준 | 4건 | 4건 | ❌ 크래시 |
| 홍일 | 1건 | 1건 | ✅ 정상 |

`Array.sort`는 원소가 2개 이상일 때만 비교함수를 호출한다 → 홍일(1건)은 **우연히** 멀쩡했던 것.

### 작업 내용 (index.html 단일 파일)
- **A. 정렬 크래시** — `renderAlbaModal()`이 신버전 스케줄에 없는 레거시 `date`를 참조.
  프로젝트 내 나머지 5곳(`_albaDateRange`, `_albaSchedsOnDate`, `_albaSchedForm`,
  `showAlbaWorkerPreview`)이 모두 쓰던 `startDate||date` 폴백으로 통일. **이 1줄만 5223행에서
  폴백이 빠져 있었음.**
- **B. 클라우드 저장 누락 (A의 연쇄 피해, 더 심각)** — `saveAlbaSchedAdd`/`saveAlbaSchedEdit`/
  `deleteAlbaSchedule`이 `saveAlbaLocal() → 화면복귀 → await _syncAlbaCloud()` 순서라,
  화면복귀에서 A가 터지면 **클라우드 동기화가 통째로 스킵**됐다(폰에서 넣은 스케줄이 PC에서
  안 보이는 원인). 순서를 `로컬 → 클라우드 → 화면` 으로 재배치.
- **C. 모바일 `+N개` 완전 먹통** — `showAlbaDayOverflow()`가 공용 `hover-preview`를 재사용했는데
  그 요소는 `@media(max-width:767px){display:none!important}`. 인라인 `display:block`보다
  `!important`가 이겨서 폰에서 렌더링 자체가 안 됐다. `MAX_CHIPS=2`라 **하루 3건 이상이면
  3번째부터 조회·수정·삭제 불가**. 전용 `day_list` 모달로 교체 → 데스크톱에서 팝업이 안 닫히던
  문제도 동시 해결.
- **D. UX (사장님 결정)** — 칩 클릭은 `sched_view` 상세(암호 없음), 그 안의 ✏️/🗑에서만 암호 ****.
  달력 칸 전체 클릭 제거하고 칸 안 `＋`(터치타겟 28px)로만 추가 → 모바일 오터치 방지.
- **E. 부수** — 알바 이름 수정 시 `schedules[].workerName` 동기화, 알바 0명일 때 폼 안내문구,
  캘린더 전환(`40d0471`) 이후 죽어 있던 CSS `.alba-tl2-*`/`.alba-sched-item` 계열 제거.
- **비서 보완** — builder 산출물 검토 중, 새로 만든 `day_list`/`sched_view` 모달에서 🗑삭제 시
  모달이 갱신되지 않고 삭제된 항목이 남는 빈틈을 발견해 직접 수정(계획서 누락분).

### 검증
- `node --check` (script 블록 추출) 통과, 페이지 JS 오류 0건
- **Playwright 실브라우저 검증 13항목 전수 통과** (모바일 390px):
  배준 4건 모달 오픈·정렬 / 홍일 1건 회귀없음 / 모바일 `+N개` 모달 표시·3건 전부 노출 /
  칩 클릭 시 암호창 안 뜸 / ✏️수정에서만 암호창 뜸 / 빈칸 클릭 무반응 / ＋ 버튼만 추가 동작

### 감사실장 지적 후속조치 (같은 세션 내 반영 완료)
- **day_list 저장 흐름 비대칭** — 삭제만 목록을 유지하고 수정/추가는 모달이 통째로 닫히며 달력으로
  튕겨나가던 문제. `albaSchedFrom` 상태 + `_albaBackFromSchedForm()` 신설로 **알바 상세 → day_list
  목록 → 달력** 순으로 원래 있던 화면에 복귀하도록 통일(취소 버튼 포함).
- **`_syncAlbaCloud` 타임아웃 부재** — 저장 순서를 클라우드 우선으로 바꾼 탓에, 응답이 안 오면
  모달이 무한 대기해 **원래 신고였던 "먹통"과 똑같이 보일** 위험이 있었음. `AbortController` +
  20초 타임아웃(`ALBA_SYNC_TIMEOUT`) 추가 + 저장 시작 시 "☁️ 저장 중…" 토스트.
- 재검증: Playwright 실브라우저 **18항목 전수 통과**(기존 13 + day_list 복귀 4 + 타임아웃 1).

### 배포
`claude/content-analysis-v9gjwm` → `main` 머지(`528a233`), GitHub Actions **success**,
자동 버전업 `v0727-01`(`604ebf4`)로 GitHub Pages 배포 완료.

---

## 2026-07-27 🔎 보안 점검 — anon key / RLS 전수 조사 (사장님 지시, 조사만·변경 없음)
### 범위와 방법
Supabase 2개 프로젝트 전수(2/2). **데이터를 바꾸는 실험은 하지 않음** — 존재하지 않는 id를
필터로 준 PATCH/DELETE(매칭 0행)로 권한만 확인, Supabase 보안 어드바이저 병행. 조사 후 알바
데이터 2명/5건 그대로임을 재확인.

### 결과 요약 — 두 프로젝트 모두 anon에게 사실상 전권이 열려 있음

**A. `nifmnigvrjfctdimgmda` (텍스트DB — 앱 데이터 대부분)** 🔴 가장 심각
| 테이블 | 담고 있는 것 | anon SELECT | anon UPDATE | anon DELETE |
|---|---|---|---|---|
| `vehicle_data` | 알바·장비·체크리스트·차량·구글캘린더설정 등 | 열림 | 열림 | 열림 |
| `tasks` | 창고업무·사무실업무·**대표지시** | 열림 | 열림 | 열림 |
| `soundlogs` | 행사일지 전체 | 열림 | 열림 | 열림 |
| `access_logs` | 접속 기록 | 열림 | 열림 | 열림 |

anon key는 `index.html`에 평문 하드코딩되어 있고, GitHub Pages로 배포되므로 **사이트에 접속한
누구나 개발자도구로 즉시 얻을 수 있다.** 앱의 암호 `****`(알바 수정/삭제, 접수함 등)는
`prompt()` 기반 **화면단 방어일 뿐**, DB에는 어떤 방어도 없다. 즉 키를 가진 사람은 앱을 거치지
않고 행사일지·대표지시·알바 데이터를 **읽고, 고치고, 영구 삭제**할 수 있다.

**B. `poxafvsqxvcaewduhvxt` (스토리지·접수함)** 🟠
- RLS는 켜져 있으나 정책이 전부 `USING (true)` / `WITH CHECK (true)` — 사실상 무방비
  - `event_requests`(행사진행의뢰서 접수함): anon INSERT/UPDATE/DELETE 전부 허용
  - `panorama_sets`: anon INSERT/UPDATE/DELETE 전부 허용
  - `sketchup_notes`(18행): anon INSERT/UPDATE/DELETE 전부 허용
- 공개 버킷 `note-files`, `skp-library`에 광범위 SELECT 정책 → **파일 목록 전체 나열 가능**
  (공개 URL 접근에는 목록 권한이 필요 없음)
- Supabase 어드바이저 경고 11건 전원 EXTERNAL/SECURITY

### 판단
`event_requests`의 개방은 2026-07-08 사장님 승인 사항으로 CHANGELOG에 기록돼 있으나,
**A(텍스트DB 4개 테이블)는 승인 기록이 없는 기본 개방 상태**로 보인다. 영향 범위가 회사
운영 데이터 전체라 성격이 다르다.

### 조치 안 함 — 사장님 결정 대기
RLS를 조이면 **지금 동작하는 기능이 즉시 멈춘다**(앱이 전부 anon key로 직접 DB를 때리는 구조).
따라서 임의로 손대지 않았다. 선택지는 아래 보고 참조.

## 2026-07-09 ✅ 성공 — 알바관리 스케줄 캘린더 그리드화 + 로그인화면 잠금비밀번호 배너
### 배경
알바관리 스케줄 탭이 세로 리스트라 한눈에 안 들어온다는 피드백 → 아이폰 캘린더처럼 월간 그리드로
요청. 별도로 로그인화면에 "강구안 잠금비밀번호" 고정 안내 배너 요청.

### 작업 내용
- **로그인화면**: 로고 아래 "🔒 강구안 잠금비밀번호: 6335" 고정 배너 추가(비서가 직접 수정)
- **알바관리 스케줄**: `renderAlbaSchedule()`을 세로 리스트에서 7열 월간 캘린더 그리드로 전면
  재구현
  - `_albaSchedsOnDate(dateKey)` 신설 — 날짜 범위(`start<=날짜<=end`) 기준으로 각 칸에 정확히
    매칭(기존엔 시작일에만 몰아서 표시하던 방식, 월경계 넘는 스케줄도 이제 정확)
  - 이전/다음달 빈칸 자동 채움으로 항상 완전한 주 단위 그리드, 오늘 날짜 강조
  - 칸당 칩 2개까지, 초과분은 "+N개"로 접어 클릭 시 기존 `showHoverPreview` 패턴으로 전체 목록
  - 날짜 칸 클릭 → 그 날짜가 미리 채워진 채로 새 스케줄 추가(`openAlbaSchedAdd(dateKey)`)
  - 기존 칩/호버프리뷰/등록·수정 폼·저장 로직은 그대로 재사용, 안 건드림

### 검증 (auditor, sonnet)
- 날짜 매칭 로직을 6개월 케이스(윤년, 연도경계, 5/6주 등)로 직접 시뮬레이션해 전부 정상 확인
- 오버플로우·날짜클릭 추가 흐름·이벤트 버블링(stopPropagation) 코드 대조 확인
- 기존 기능(스케줄 수정모달, 월이동, 저장) 이번 커밋에서 미변경 확인, 문법 검증 통과

### 참고 (범위 밖, 조치 안 함)
`renderAlbaModal()`(5223줄 근처)의 정렬 코드가 레거시 `date` 필드를 직접 참조해서
(`b.date.localeCompare(a.date)`) 신버전 스케줄(`date` 필드 없음)에서 `undefined.localeCompare`
오류가 날 수 있는 기존 버그를 builder가 발견함. 이번 작업 범위 밖이라 손 안 댐 — 사장님께 별도 보고 예정.

### 결과
- **작업 완료** — ✅ 통과
- 파일: `index.html` (로그인화면 배너, `renderAlbaSchedule()` 및 관련 함수/CSS)
- 브랜치: `claude/content-analysis-v9gjwm` → main 배포 예정

---

## 2026-07-09 ✅ 성공 — 알바관리 스케줄 수정 모달 안 열리던 버그 수정
### 배경
"알바관리에 스케쥴 등록하고 수정할려면 안 된다"는 신고. 조사(Playwright로 실제 재현) 결과 등록은
정상이고, "스케줄" 탭 달력에서 스케줄 칩을 클릭해 수정하려 할 때만 문제 재현됨.

### 원인
`openAlbaSchedEdit()`(`index.html:5421`)가 `renderAlbaModal()`로 수정 폼 내용은 정상 생성하지만,
부모 모달 오버레이(`#albaModal`)에 `open` 클래스를 안 붙여서 CSS `display:none`이 그대로 유지 —
사용자에게는 수정 암호(****) 입력 후 아무 반응 없는 것처럼 보임. 같은 계열의 다른 모든 "열기"
함수(`openAlbaWorkerView`, `openAlbaWorkerAdd`, `openAlbaSchedAdd`)는 전부 정상적으로
`classList.add('open')`을 호출하는데 이 함수만 누락되어 있던 구조적 결함.

### 작업 내용
- `openAlbaSchedEdit()`의 `renderAlbaModal();` 다음 줄에 `document.getElementById('albaModal').
  classList.add('open');` 한 줄 추가 (비서가 직접 수정 — 원인이 이미 명확해 builder 안 거침)

### 검증 (auditor, sonnet)
- 다른 3개 open 함수와 element/클래스명 100% 동일 패턴 확인
- `closeAlbaModal()`의 `remove('open')`과 정합성 확인, 저장 후 열고 닫는 흐름 정상
- diff 정확히 1줄 추가만 있음, 문법 검증 통과

### 결과
- **작업 완료** — ✅ 통과 (최초 감사에서 문서화 누락 지적받아 이 기록으로 보완 — 문서화 누락이
  반복되고 있어 앞으로는 코드 커밋과 문서 갱신을 같은 배치로 처리하기로 함)
- 파일: `index.html:5428`
- 브랜치: `claude/content-analysis-v9gjwm` → main 배포 예정

---

## 2026-07-09 ✅ 성공 — 장비관리 "관리내역" 저장 유실 버그 수정
### 배경
"장비관리에서 항목 수정 후 저장하면 저장이 안 된다, 메모란인 것 같다"는 신고. 조사 결과 진짜
저장 실패가 아니라, 편집 모달의 "관리내역"(수리내용/업체명/날짜) 입력칸이 메인 "💾 수정 저장"
버튼과 별개로 자체 "추가" 버튼으로만 저장되도록 설계돼 있어서, 사용자가 이 칸을 범용 메모란으로
착각해 입력 후 메인 저장 버튼만 누르면 그 내용이 에러 없이 조용히 버려지던 UI 설계 결함.

### 작업 내용
- `_readEquipLogInput()` 헬퍼 신설(`index.html:6161`) — 수리내용(`elDesc`) 비어있으면 `null`,
  있으면 `{date,desc,place}` 반환
- `addEquipLog()`를 이 헬퍼로 리팩토링(중복 로직 제거, 기존 동작 동일)
- `saveEquipEdit()`에서 저장 직전 이 헬퍼로 입력칸 값을 확인해, 값이 있으면 로그를 자동으로
  `logs` 배열에 추가한 뒤 기존 저장 흐름 그대로 진행. "추가" 버튼으로 이미 로그를 넣어둔 경우엔
  재렌더링으로 입력칸이 비어있어 중복 추가 안 됨

### 검증 (auditor, sonnet)
- 코드 검토로 헬퍼 반환값, 중복 추가 방지, 로그 필드 구조 일치(`_renderLogsSection`과 대조) 확인
- 문법 검증 통과, `pageAlba`/`pageVehicle` 등 다른 탭 미변경 확인
- 엣지케이스 확인: 날짜만 채우고 수리내용은 비운 채 저장하면 조용히 버려짐(기존 `addEquipLog()`도
  desc 필수 취급이라 새로 생긴 버그는 아님, 사소한 UX 갭으로 기록만 해둠)

### 결과
- **작업 완료** — ✅ 통과 (최초 감사에서 문서화 누락 지적받아 이 기록으로 보완)
- 파일: `index.html` (6161~6285줄 근처)
- 브랜치: `claude/content-analysis-v9gjwm` → main 배포 예정

---

## 2026-07-09 ⏸️ 보류 — DB 조회전용(read-only) MCP 도입 시도
### 배경
Supabase 데이터를 대화로 바로 조회/디버깅할 수 있게, 쓰기 권한이 원천 차단된 별도 MCP 연결을
만들려고 시도. 사장님이 5단계 프로세스(스택확인→연결정보→안전장치→연결테스트→감사) 요청.

### 이 프로젝트의 DB 구조 (확인 완료, 재조사 불필요)
- 순수 정적 HTML/JS(GitHub Pages), package.json/.env/마이그레이션 파일 전혀 없음
- 서로 다른 Supabase 프로젝트 **2개**를 클라이언트 코드에 anon key 하드코딩해서 직접 REST 호출:
  - **창고 A** `nifmnigvrjfctdimgmda` — `index.html`(`SB_URL`/`SB_KEY`), soundlogs/tasks/
    vehicle_data/access_logs 등 핵심 운영 데이터 + Realtime
  - **창고 B** `poxafvsqxvcaewduhvxt` — `index.html`(`STORAGE_URL`/`STORAGE_KEY`, Storage),
    `event-request/index.html`, `event-request/hub/index.html` 공유. event_requests 테이블 +
    notify-telegram Edge Function
- 비서의 Supabase MCP는 창고 B만 접근 가능(창고 A는 다른 계정/조직이라 접근 불가 — 창고 A
  작업은 항상 사장님이 대시보드에서 직접 SQL 실행 필요)

### 진행한 작업
1. 두 프로젝트 모두에 `mcp_readonly` role 생성 — `public` 스키마 SELECT만 부여, INSERT/UPDATE/
   DELETE/DDL 권한 없음, `default_transaction_read_only=on`, 이후 `BYPASSRLS`도 추가(RLS 때문에
   0건으로 보이는 문제 해결용)
2. 표준 Postgres MCP 서버(`@modelcontextprotocol/server-postgres`)를 사장님 로컬 Claude
   Desktop에 연결 시도 — Supabase 무료 요금제 "Shared Pooler"(IPv4, `aws-N-지역.pooler.
   supabase.com:6543`) 경유로 연결

### ❌ 발견한 치명적 문제 (미해결, 다음 작업 시 여기서 재개할 것)
**Shared Pooler로 연결하면 `mcp_readonly`로 접속해도 실제로는 `postgres`(관리자) 권한으로
동작함.** `SELECT current_user, session_user;` 실행 결과 둘 다 `postgres`로 나옴 — 실제로
INSERT까지 성공해버림(테스트 행은 확인 후 바로 삭제 완료, `id: ecfa0d21-...`).
- 원인: Supabase 문서/이슈(Custom Database Roles 관련 논의)에 근거해, 무료 요금제의 Shared
  Pooler(Supavisor)가 커스텀 role을 제대로 구분하지 못하고 관리자 권한으로 라우팅하는 것으로
  추정됨(공식 문서에 명시적 확인은 못함, 정황 근거).
- **현재 조치**: 위험하므로 사장님 로컬 Claude Desktop의 MCP 설정에서 두 연결(`hanbada-db-storage`,
  `hanbada-db-main`) 전부 제거 완료. 이 세션의 임시 등록도 제거 완료. **현재 어디에도 활성화된
  DB MCP 연결 없음 — 안전한 상태.**

### 다음 시도 후보 (미착수, 사장님이 시간 날 때 재개)
1. **Direct Connection 시도** (우선 추천) — `db.<project-ref>.supabase.co:5432`로 pooler 없이
   직접 연결. Supavisor 라우팅을 거치지 않아 role이 정확히 적용될 가능성 높음. 단, 무료
   요금제에서 Direct Connection은 **IPv6 전용** — 사장님 자택/사무실 네트워크가 IPv6를
   지원하는지 확인 필요(안 되면 이 방법 불가).
2. **PostgREST + 커스텀 서명 JWT 방식** — `role: mcp_readonly` claim을 담은 JWT를 프로젝트 JWT
   시크릿으로 직접 서명해서, 표준 REST API(`/rest/v1/...`)로 조회. 네트워크 제약 없이(HTTPS만
   쓰므로) 확실히 동작하지만, Supabase 대시보드에서 JWT 시크릿(민감정보)을 추가로 받아와야 하고
   구현이 더 복잡함.
3. (참고) 이 비서가 일하는 원격 세션 환경 자체는 HTTPS(443) 외 포트가 전부 막혀있어서, Postgres
   MCP는 애초에 **사장님 로컬 PC에서만** 시도 가능 — 이 세션에서는 절대 안 됨(직접 확인함).

### 생성된 자원 (다음 작업 시 재사용 가능, 삭제 안 함)
- 창고 A, 창고 B 모두 `mcp_readonly` role 존재(SELECT-only + BYPASSRLS). 비밀번호는 각각
  이 대화에서 전달됨(사장님 로컬에만 보관, 저장소엔 없음). 필요시 대시보드에서 비밀번호
  재설정 가능.

---

## 2026-07-08 ✅ 성공 — 무대계산기 모바일 왼쪽 쏠림 수정 + 접수함 게시판화 + 폼 필드 정리
### 배경
폰에서 무대계산기 배치 캔버스가 왼쪽으로 쏠려 보인다는 신고. Explore 조사 결과 PC 전용
미디어쿼리에만 있던 중앙정렬(`margin:0 auto`)이 모바일 기본 스타일엔 빠져있던 게 원인.
같은 시간대에 접수함 UI를 카드형→게시판(테이블)형으로 바꾸고, 행사진행의뢰서 폼의 여러
필드(행사종류/장소정보/필요서비스/천막수량/견적서/첨부안내)도 요청대로 정리함.

### 작업 내용
- **무대계산기**: `#stagecalcCanvas`(`index.html:1474`)에 `margin:0 auto` 추가(PC 미디어쿼리와
  동일 규칙을 모바일 기본에도 적용), 화면 리사이즈/회전 시 재계산하는 디바운스 리스너 추가
  (`switchTab()`의 active 클래스 흐름과 대조해 `#pageStage` 활성 상태일 때만 재계산하도록 확인)
- **접수함**: 카드 목록 → 번호/행사명/담당자·소속/연락처/접수일시/관리(수정,삭제) 컬럼의 표
  형식으로 재구성. 관리 컬럼에서 목록 클릭 없이 바로 수정/삭제 가능(기존 비밀번호 재확인 로직
  재사용)
- **폼 필드 정리** (`event-request/index.html`):
  - 행사종류: 결혼식/종교행사/기념식 삭제, 체육대회/이취임식및기념식 추가, 학교행사→교내축제,
    순서를 축제·교내축제·공연콘서트·이취임식및기념식·체육대회·기업행사컨퍼런스·기타로 재배치
  - 실내/실외에서 "혼합" 삭제, "장소 대관 여부" 문항 전체 삭제(DB `venue_status` NOT NULL 해제)
  - 필요한 서비스: 무대,음향,조명,트러스,LED전광판,ENG카메라,천막/테이블/의자,기타로 재정렬
    (사회자(MC) 삭제)
  - 천막 수량 → "천막(캐노피및몽골)/테이블/의자 수량"으로 확장, 테이블/의자 개수 입력 추가
  - "견적서 필요 여부" 문항 전체 삭제
  - 첨부파일 안내 문구를 "행사계획서 또는 참고이미지등을 첨부해 주세요"로 변경
- **로그인화면**: 실제 로고 이미지 삽입 후 중복되던 텍스트 로고/영문 서브타이틀 삭제

### 검증 (auditor, sonnet)
- 무대계산기: CSS diff, switchTab 실제 코드와 리사이즈 조건 대조, scDrawDiagram 반복호출 안전성
  확인, 문법검증 — 전부 ✅
- 폼 필드 정리: curl로 venue_status/quote_email 없는 payload가 실제 insert 성공하는지 실증 확인

### 결과
- **작업 완료** — ✅ 통과
- 파일: `index.html`, `event-request/index.html`, `event-request/hub/index.html`
- 브랜치: `claude/content-analysis-v9gjwm` → main 배포 완료

---

## 2026-07-08 ✅ 성공 — 접수함 수정/삭제 + 화면 네비게이션 + 로고 + 이메일 확장
### 배경
접수함에서 제출 내용을 잘못 적었거나 취소된 건을 관리할 방법이 없어서 수정/삭제 요청. 화면
전환이 무조건 첫 선택화면으로만 돌아가서 불편하다는 지적으로 뒤로/앞으로 네비게이션 요청.
로고는 event-request 폼에만 있었는데 메인 로그인화면에도 요청. 이메일 보내기는 Gmail/네이버
사용자를 위해 확장 요청.

### 작업 내용
- **RLS 추가 개방**: `event_requests`에 anon UPDATE/DELETE 정책 신규 허용(비서가 Supabase MCP로
  직접 적용, SELECT 개방 때와 같은 성격의 리스크 — anon key를 아는 사람은 이제 데이터를 고치거나
  영구 삭제도 가능. 사장님 기존 방침에 따라 진행)
- `event-request/hub/index.html` 접수함 상세보기에 ✏️수정(인라인 편집 폼)/🗑️삭제 버튼 추가.
  **삭제는 confirm() 1차 확인 + 비밀번호(****) 2차 확인**, 수정 저장도 비밀번호 확인 후 PATCH —
  실행 순간에만 비밀번호 요구, 편집모드 진입 자체는 자유
  (사장님이 추가 지시: "삭제,수정에 **** 비밀번호걸고 만들어라" — builder 작업 중간에 전달, 같은
  세션 내에서 반영됨)
- 허브 3개 화면(선택/접수함/양식서보내기)에 브라우저 히스토리 방식 뒤로/앞으로 버튼 추가
  (`screenHistory` 배열 + `historyIndex`), 갈 곳 없으면 버튼 비활성화
- `index.html` 로그인화면에 실제 로고 이미지(`한바다로고2.png`, 저장소 루트) 삽입 — 기존
  "한바다일지" 텍스트 로고는 위쪽에 이미지 추가하는 방식으로 유지
- `event-request/hub/index.html` "양식서 보내기"에 Gmail 웹 작성(공식 지원 URL)/네이버메일 웹
  작성 버튼 추가 — 네이버는 비공식 URL이라 제목/본문 자동입력이 100% 보장 안 됨을 사장님께 안내함

### 검증 (auditor, sonnet)
- curl로 INSERT→PATCH→DELETE 전체 흐름 실증(테스트 데이터로 실제 수정·삭제 확인, 정리까지 완료)
- 코드 검토: 비밀번호 게이트가 실제 실행 직전에만 걸리는지, 취소/오답 시 API 호출 자체가 안
  나가는지, 로컬 목록이 수정/삭제 후 즉시 갱신되는지, 히스토리 네비게이션이 뒤로→앞으로 왕복
  가능한지, 로고 파일명이 실제 파일과 바이트 단위로 일치하는지 전부 확인
- git 상태 clean, 커밋 하나(`6df0fb2`)에 정리됨

### 결과
- **작업 완료** — ✅ 통과
- 파일: `event-request/hub/index.html`, `index.html`
- 커밋: `6df0fb2`
- 브랜치: `claude/content-analysis-v9gjwm` (main 배포 대기 중)

---

## 2026-07-08 ✅ 성공 — 텔레그램 CORS 버그 수정 + 접수함 허브페이지 이전
### 배경
텔레그램 알림을 연동했는데 사장님이 실제로 제출해보니 알림이 안 옴. curl로는 계속 정상이라
sonnet 감사로도 원인을 못 잡아서 opus로 격상 재검증 요청받음. 동시에 접수함(제출목록 조회)을
메인 앱 탭에서 빼서, 로그인화면 비밀번호 통과 후 별도 중간페이지로 옮기고 "양식서 보내기"
기능을 추가하라는 지시도 받음.

### 원인 (opus 감사, 확증)
`notify-telegram` Edge Function이 브라우저 CORS preflight(OPTIONS)를 처리하지 않음.
`apikey`/`Authorization`/`Content-Type` 커스텀 헤더를 쓰는 fetch는 브라우저가 반드시 OPTIONS를
먼저 보내는데, 이 함수는 OPTIONS에 405 + CORS 헤더 없음으로 응답 → 브라우저가 실제 POST를
아예 보내지도 못하고 차단. **curl은 preflight를 안 하므로 이 버그를 못 잡았던 것** — "curl 통과
≠ 브라우저 통과"가 이번 사건의 핵심 교훈. `event_requests` insert(PostgREST)는 Supabase가
CORS를 자동 처리해줘서 정상 동작했기 때문에, DB엔 row가 쌓이는데 알림만 안 가는 상황이었음.

### 수정
- `notify-telegram` 함수에 `OPTIONS` 메서드 처리 + 모든 응답에 `Access-Control-Allow-Origin/
  Headers(apikey 포함)/Methods` 헤더 추가 후 재배포(version 2)
- 실제 브라우저 preflight를 재현한 curl(`-X OPTIONS` + `Origin` 헤더)로 200 + CORS 헤더 확인
- 접수함 기능을 `index.html`(nav 탭/페이지/함수 전부)에서 제거하고 새 독립 페이지
  `event-request/hub/index.html`로 이전. 허브 페이지는 "📥 접수함"(기존 목록+상세 그대로)과
  "📝 양식서 보내기"(mailto 이메일 + `navigator.share`/클립보드 복사 폴백, 카카오 SDK 앱등록 없이
  구현) 두 선택지 제공
- `openEventRequestForm()`의 이동 경로를 `event-request/`(공개폼 직행)에서 `event-request/hub/`로
  변경. 클라이언트용 공개 폼(`event-request/index.html`)은 무변경

### 검증 (auditor)
- CORS: opus가 라이브 함수에 OPTIONS/POST 3종 재현 테스트로 원인 확증, sonnet이 재배포 후
  동일 테스트로 수정 확인
- 허브 이전: `index.html`에서 접수함 관련 코드 잔여 참조 0건, `event-request/hub/`의 Supabase
  필드 매핑이 실제 curl 조회 결과와 100% 일치, 공개 폼 링크가 hub가 아닌 올바른 클라이언트
  경로를 가리킴, `event-request/index.html`은 diff에 없음(무변경) 확인

### 결과
- **작업 완료** — ✅ 통과
- 파일: `index.html`(접수함 제거+버튼경로 변경), `event-request/hub/index.html`(신규),
  Supabase Edge Function `notify-telegram`(version 2)
- 커밋: `d09d4cc`
- 브랜치: `claude/content-analysis-v9gjwm` (main 배포 대기 중)

### 교훈
- 외부 API 연동 기능은 **curl 검증만으로 브라우저 동작을 보장할 수 없음** — CORS preflight는
  curl이 자동으로 보내지 않으므로, fetch에 커스텀 헤더가 있는 기능은 `-X OPTIONS` 재현 테스트를
  검증 항목에 기본 포함할 것

---

## 2026-07-08 ✅ 성공 — 폼 제출 시 텔레그램 알림 연동
### 배경
클라이언트가 행사진행의뢰서를 제출하면 사장님이 바로 알아야 하므로(접수함 탭은 직접 들어가서
확인해야 함), 제출 즉시 텔레그램 그룹("한바다 접수알림")으로 알림이 가도록 요청.

### 작업 내용
- Supabase Edge Function `notify-telegram`(프로젝트 poxafvsqxvcaewduhvxt) 신규 배포 — 텔레그램
  Bot Token/Chat ID를 함수 코드 내부에만 보관(Supabase 서버에만 존재, git 저장소·클라이언트 JS
  어디에도 노출 안 됨), `verify_jwt: true`로 익명 무단 호출 차단
- `event-request/index.html`: 폼 제출(Supabase insert) **성공 이후에만** 이 함수를
  fire-and-forget으로 호출해 담당자/소속/행사명/일시/연락처/이메일/예산 요약을 텔레그램으로 전송.
  알림 실패해도 `.catch`로 무시 — 제출 자체는 항상 정상 완료
- honeypot(봇 차단) 걸리면 이 호출 이전에 이미 `return`되므로 스팸 알림 발송 안 됨

### 검증 (auditor, sonnet)
- 토큰 비노출: 저장소 전체 + git 히스토리 전체에서 봇 토큰 문자열 검색 → 0건 (CONFIRMED 안전)
- curl 실증: 정상 호출 → 200 `{"ok":true}` + 실제 텔레그램 메시지 도착 확인, 인증 헤더 없이 호출 →
  401 `UNAUTHORIZED_NO_AUTH_HEADER`로 차단 확인
- 코드 흐름: insert 실패 시 텔레그램 호출 도달 안 함, honeypot 시에도 도달 안 함 — 순서 확인
- ⚠️ 최초 감사 시 CHANGELOG.md/PROJECT_LOG.md 미반영 지적받아 이 기록으로 보완 (반복 발생 —
  이후로는 기능 커밋과 문서 갱신을 같은 흐름에서 처리하도록 순서 조정)

### 결과
- **작업 완료** — ⚠️ 조건부통과 → 문서화 보완으로 해결
- 파일: `event-request/index.html`(텔레그램 호출), Supabase Edge Function `notify-telegram`(신규)
- 커밋: `0fdaa16`
- 브랜치: `claude/content-analysis-v9gjwm` (main 배포 대기 중)

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
- 로그인화면 "행사진행의뢰서" 버튼에 비밀번호(****) 게이트 추가(`openEventRequestForm()`) — 외부
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
