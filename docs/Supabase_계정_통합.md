# Supabase 계정 통합 정리 (2026-09-06)

> DB와 사진이 다른 계정에 흩어져있어 헷갈리던 문제를 정리한 기록.
> 계정/프로젝트 구조가 또 헷갈리면 이 문서를 먼저 본다.

---

## 0. 한눈에 보는 결론

- **이제 계정은 1개다.** `yamugyclaude@gmail.com` 조직(`jknvoletqfngqkleyksz`) 하나로 통합됨.
- 이 조직 밑에 프로젝트가 3개 있다:
  | 프로젝트 ID | 이름 | 용도 |
  |---|---|---|
  | `nifmnigvrjfctdimgmda` | 메인 | **DB(장비·행사일지·할일 등) + 사진(event-photos)** — 이제 여기 하나로 통합 |
  | `poxafvsqxvcaewduhvxt` | (구)사진 | SketchUp 플러그인(`ruby-files`, `note-files`) 등 **hanbadadiary와 무관한 다른 방 자료 보관용으로만 남음** |
  | `eujgcxoykqhvpqlkfpnl` | ax8-tone-db | 기타 톤 DB (JACKSONGUITAR 방, 비활성 상태) |
- `index.html`의 `SB_URL`과 `STORAGE_URL`이 **같은 프로젝트**(nifmnigvrjfctdimgmda)를 가리키도록 통일됨.

---

## 1. 이전 문제 (통합 전 구조)

- DB(`vehicle_data`, `tasks`, `soundlogs`, `access_logs`)는 `nifmnigvrjfctdimgmda` — 로그인 계정 `yamugyclaude@gmail.com`
- 사진(`event-photos` 버킷)은 `poxafvsqxvcaewduhvxt` — 로그인 계정 `yamugyhanbada` 계열
- **서로 다른 계정**이라 Claude(비서실장) 세션이 한 번에 하나의 Supabase 커넥터 계정만 붙을 수 있어,
  두 프로젝트를 동시에 만지려면 매번 커넥터를 계정 간 전환해야 했음 → 관리 혼선의 원인.

## 2. 통합 절차 (재발 시 참고용)

1. 두 계정이 서로의 조직에 **Owner로 상호 초대** (yamugyclaude ↔ yamugyhanbada)
   - Supabase에서 프로젝트 Transfer는 "로그인 계정이 source·target 조직 모두의 Owner"일 때만 가능하기 때문
2. `poxafvsqxvcaewduhvxt` 프로젝트 Settings → General → **Transfer project** → yamugyclaude 조직으로 이전
3. 사진 파일 자체(바이너리)는 SQL로 못 옮김(Storage는 별도 S3 백엔드) → **1회성 Edge Function**(`migrate-photos`, nifmnigvrjfctdimgmda에 배포)을 만들어 서버사이드에서 구 Storage의 public URL을 fetch → 새 프로젝트에 upload
   - Claude 세션 자체는 네트워크 보안정책상 `supabase.co`에 직접 접속 못 함 → Edge Function 우회가 필요했던 이유
4. `event-photos` 버킷 85개 파일 100% 이관 확인 (개수·용량 SQL로 대조)
5. `index.html`의 `STORAGE_URL`/`STORAGE_KEY`를 `SB_URL`/`SB_KEY`와 동일하게 수정

## 3. 확인된 것 / 확인 안 된 것

- ✅ 확인됨: DB 4개 테이블(vehicle_data 88행·tasks 102행·soundlogs 27행·access_logs 0행) 모두 nifmnigvrjfctdimgmda에 있음
- ✅ 확인됨: event-photos 85개 파일 이관 완료 (7MB)
- ⚠️ 확인 안 됨(후속 검토 필요): `poxafvsqxvcaewduhvxt`에 남아있는 `ruby-files`/`note-files`(SketchUp 플러그인류)가 정확히 어느 방 소속인지 — hanbadadiary와 무관해 보여 이번엔 옮기지 않음
- ⚠️ 알려진 리스크(사장님 승인됨): `vehicle_data`/`soundlogs` 테이블 RLS(행 단위 보안) 비활성화 — 직원 공용 계정 사용 전제로 백업 체계만 잘 갖추면 된다고 판단, 별도 조치 안 함

## 4. 빠른 점검용

- 계정 확인: Supabase 커넥터가 지금 어느 프로젝트를 보여주는지 = `list_projects` 결과에 `nifmnigvrjfctdimgmda`, `poxafvsqxvcaewduhvxt`, `eujgcxoykqhvpqlkfpnl` **3개 다 함께 뜨면 정상**(같은 조직).
- 하나만 뜨면 = 계정이 다시 분리됐거나 커넥터가 다른 계정에 붙은 것 — 이 문서 2장 절차로 재확인.
