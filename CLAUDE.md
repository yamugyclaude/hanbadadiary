# SoundLog — 한바다 작업일지

음향 행사 관리 앱. 단일 파일 SPA로, 모든 코드가 `index.html` 하나에 있습니다.

## 기술 스택

| 항목 | 내용 |
|---|---|
| 파일 구조 | `index.html` 단일 파일 (HTML + CSS + JS 일체) |
| 백엔드 | Supabase (REST API + Realtime WebSocket) |
| 배포 | GitHub Pages (`git push origin main` → 자동 배포) |
| 저장소 | https://github.com/yamugyclaude/hanbadadiary |

## Supabase 설정

- **URL**: `https://nifmnigvrjfctdimgmda.supabase.co`
- **Key**: 코드 내 `SB_KEY` 상수 참조 (anon key)

### 테이블 구조

| 테이블 | 용도 |
|---|---|
| `soundlogs` | 행사일지 (id, date, event_name, data, md_content) |
| `tasks` | 창고/사무실/대표지시 업무 (id, type, title, body, status, priority, due, data) |
| `vehicle_data` | 차량 정비 기록. `id='singleton'`이 실제 차량 데이터, `id='sl_users'`가 사용자 목록 저장에 사용됨 |
| `access_logs` | 접속·행동 로그 |

## 주요 기능 탭

| 탭 | 페이지 ID | 설명 |
|---|---|---|
| 📋 행사일지 | `pageList` / `pageForm` | 행사 기록 작성·조회 |
| 🏭 창고업무 | `pageWarehouse` | 업무 카드 관리 |
| 🏢 사무실업무 | `pageOffice` | 업무 카드 관리 |
| 👔 대표지시 | `pageDirective` | 지시사항 관리 |
| 🚛 차량관리 | `pageVehicle` | 1.5톤·3.5톤 정비 기록 |

## 인증 시스템

- 로그인: `doLogin()` — 로컬 미발견 시 클라우드 자동 조회
- 회원가입: `doRegister()` — 관리자 승인 코드 필요 (`REGISTER_CODE = '6293'`)
- 관리자 계정: `id='admin'`, `pw='6293'` (앱 최초 실행 시 자동 생성)
- 사용자 데이터: `vehicle_data` 테이블 `id='sl_users'` 행에 JSON 배열로 저장

## 동기화 구조

```
저장 버튼 클릭
  → localStorage 업데이트
  → Supabase upsert (sbUpsertLog / syncOneTaskToCloud / saveVehicleManual)

다른 기기
  → WebSocket Realtime 수신 (soundlogs, tasks, vehicle_data)
  → localStorage 자동 업데이트 + 화면 갱신
```

## 배포 방법

```bash
# 수정 후
git add index.html CHANGELOG.md
git commit -m "fix: 변경 내용 요약"
git push origin main
# → GitHub Pages 자동 배포 (약 30초~1분 소요)
```

## 변경사항 기록 규칙

수정 후 배포할 때마다 `CHANGELOG.md`에 항목을 추가합니다.

```markdown
## [YYYY-MM-DD] — 변경 제목
**커밋**: `해시`
### 추가 / 수정 / 삭제
- 내용
```

## 다른 기기에서 작업 시작하는 법

```bash
# 1. 저장소 클론 (최초 1회)
git clone https://github.com/yamugyclaude/hanbadadiary.git
cd hanbadadiary

# 2. 최신 코드 받기 (이미 클론된 경우)
git pull origin main

# 3. Claude Code 실행
claude
```

Claude Code가 이 `CLAUDE.md`를 자동으로 읽어 프로젝트 맥락을 즉시 파악합니다.
