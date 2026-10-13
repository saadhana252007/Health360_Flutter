# Health360 AI: Kotlin/XML → Flutter Migration Plan (v2)

Repo: `saadhana252007/Health360_AI` (private) · Verified against commit `5c3fa57` plus the two backend files fixed in section 2.

---

## 0. Paste this into Antigravity first

```
You are migrating an Android app (Kotlin + XML Views) to Flutter.

Workspace layout:
  ./Health360_AI/                 the existing repo. READ-ONLY reference. Do not edit it.
    android/Health360AI/...       the Kotlin app to port
    backend/                      FastAPI backend (stays as is)
  ./health360_flutter/            the new Flutter app. All your work goes here.

Rules:
1. Read MIGRATION_PLAN.md in ./health360_flutter/ completely before writing code.
2. Work on ONE item from the Progress checklist at a time, in order.
3. Before writing Dart for an item, read the Kotlin files listed for it. Port the behaviour, field names, numeric encodings, validation rules and error messages exactly. Do not invent new ones.
4. Never put secrets in code. Config comes from --dart-define (see plan section 5).
5. After each item: run `flutter analyze`, fix problems, tick the item in the checklist, and summarise what changed in 3 lines.
6. Stop after each item and wait for me to say "next".

Start with item 1.
```

If your usage limit runs out and you switch accounts, open the same workspace and send:
*"Read MIGRATION_PLAN.md. Continue from the first unchecked item in section 9. Follow the rules in section 0."*
Commit to Git after every item so you can always roll back.

---

## 1. What the app is

| Layer | Current | Decision |
|---|---|---|
| Client | Kotlin, XML Views, ViewBinding, 9 Activities + 4 Fragments, ~4,500 lines | **Rewrite in Flutter** |
| Auth + DB | Supabase Auth (PKCE) + Postgres tables `profiles`, `checkups` | Keep. Use `supabase_flutter` |
| Backend | FastAPI (`backend/`), PyTorch/XGBoost models, Groq assistant | **Keep unchanged** |

```
Flutter app ──(supabase_flutter)──► Supabase Auth, `profiles` (read/write), `checkups` (read)
     │
     └──(dio + Bearer token)─────► FastAPI: POST /api/v1/checkups/analyze
                                           POST /api/v1/checkups/analyze-image
                                           POST /api/v1/assistant/chat
```

The backend decides who the user is from the Bearer token. **The Flutter app must not send `user_id`** (the server ignores it).

---

## 2. Status of the pre-migration fixes

| # | Fix | Status |
|---|---|---|
| 1 | `.gitignore` `data/` → `/data/`; missing Android files pushed | ✅ Done and verified |
| 2 | Backend takes user from login token (`backend/auth.py`) | ✅ Done and verified (all 3 endpoints use it) |
| 3 | `/analyze` no longer saves to `SUPABASE_TEST_USER_ID` | ✅ Done |
| 4 | API URL from `local.properties`; cleartext HTTP only in debug manifest; body logging debug-only with `Authorization` redacted | ✅ Done and verified |
| 5 | **`ai_service.py` and `checkups.py` were overwritten with older versions** in the push | ⚠️ **Replace with the corrected files** (sent with this plan) |
| 6 | `android/Health360AI/app/.idea/` is committed | Minor: `git rm -r --cached android/Health360AI/app/.idea`, add `.idea/` to `.gitignore` |

**What the overwrite lost (item 5):** the memory-safe `ai_service.py` (models load on demand and are released after use, wound/symptom models behind `ENABLE_LOCAL_*` flags, inference lock, memory logging, `ModelUnavailableError` → HTTP 503) and the image checks in `checkups.py` (empty file, minimum 32×32, resize to 1024 px, JSON-object validation, error wrapping). With the older `ai_service.py`, `AIService()` loads every model, including a Hugging Face download, at server start, so a small host can run out of memory or fail to start, and the assistant endpoint goes down with it. The corrected `checkups.py` keeps your login-token changes, the threadpool calls and the 10 MB limit.

Also still open on the backend: the server must be on **HTTPS** for any release build, and Supabase RLS must be enabled (section 7).

---

## 3. Screens: Kotlin source → Flutter

All Kotlin paths are under `Health360_AI/android/Health360AI/app/src/main/java/com/example/health360ai/`. Layout XML is in `.../res/layout/`; screenshots of every screen are in `Health360_AI/docs/screenshots/`. **Use the screenshots as the visual reference**; `colors.xml` is nearly empty, so colours live inside layouts and drawables.

| Flutter screen | Kotlin source | Behaviour to port |
|---|---|---|
| `LoginScreen` | `ui/auth/MainActivity.kt` | Email + password sign-in; "Forgot password" dialog sends reset email |
| `RegisterScreen` | `ui/auth/RegisterActivity.kt` | Name, DOB (date picker), sex (dropdown), height, weight, email, password (min 8) + confirm. See quirk Q1 |
| `ResetPasswordScreen` | `ui/auth/ResetPasswordActivity.kt` | Opened by `health360://login/reset`; sets new password. Must be a separate screen so a recovery session never counts as a normal login |
| `HomeShell` (bottom nav) | `ui/home/HomeActivity.kt` | 4 tabs: Home, History, Assistant, Profile |
| `HomeScreen` | `ui/home/HomeFragment.kt` | Greeting from profile name; latest checkup: score as %, last date, risk status = `overall_category` (or "Screening complete"); empty state "Not assessed"; "Start checkup" |
| `PatientInfoScreen` | `ui/patient/PatientInformationActivity.kt` + `PatientInformationViewModel.kt` | Prefills from `profiles`; name, DOB, sex, height, weight |
| `SymptomsScreen` | `ui/symptoms/SymptomsActivity.kt` | Complaint type (general/skin/oral/wound) changes which site options show; see encodings below |
| `VitalsScreen` | `ui/vitals/VitalsActivity.kt` | Validated vitals; see ranges below |
| `ImageInputScreen` | `ui/image/ImageInputActivity.kt` | Optional. Camera or gallery, plus image type dropdown (skin/oral/wound) |
| `ResultScreen` | `ui/result/ResultActivity.kt` (699 lines) | Shows a live result **or** a stored checkup by `checkup_id` (rebuilds the response from the DB row). Split into small widgets |
| `HistoryScreen` | `ui/history/HistoryFragment.kt`, `CheckupHistoryAdapter.kt`, `HistoryRepository.kt` | List newest first; tap opens Result with `checkup_id` |
| `AssistantScreen` | `ui/assistant/AssistantFragment.kt` | Chat bubbles; 3 chips send: "Explain my health screening result in simple words." / "What are my warning signs?" / "What does my confidence and uncertainty mean?"; passes `checkup_id` when opened from a result |
| `ProfileScreen` | `ui/profile/ProfileFragment.kt` | Shows email, name, DOB, sex, height, weight, member-since; Logout / Privacy & Security / About dialogs; app version |

Skip: `CheckupApiTestViewModel`, `NetworkTestViewModel`, `ExampleUnitTest`, `ExampleInstrumentedTest`, the empty ViewModels.

Flow: Login → Home → Patient → Symptoms → Vitals → Image (optional) → Submit → Result → History / Assistant.

---

## 4. Data contract (must match exactly)

### Draft state
`data/repository/CheckupStateRepository.kt` is a global singleton holding patient, symptoms, vitals, image. In Flutter use a Riverpod `CheckupDraft` notifier. Clear it after a successful submit.

### Patient payload (`patient`)
`full_name, date_of_birth, sex, height_cm, weight_kg` + vitals merged into the same object.

### Vitals (keys and validation, from `VitalsActivity.kt`)
| Key | Rule | Message |
|---|---|---|
| `heart_rate` | 30–220 | |
| `systolic_bp` | 70–250 | |
| `diastolic_bp` | 40–150 | |
| `spo2` | 70–100 | "SpO₂ must be between 70% and 100%" |
| `temperature` | 30–45 °C | "Please enter a valid body temperature between 30°C and 45°C" |
| `activity_level` | Low=0, Moderate=1, High=2 | |
| `tobacco`, `alcohol` | Yes=1, No=0 | |

Copy the exact toast messages for heart rate and BP from the Kotlin file.

### Symptoms payload (`symptoms`)
| Key | Encoding |
|---|---|
| `complaint_type` | `general` / `skin` / `oral` / `wound` |
| `severity` | number 0–10 ("Enter a severity between 0 and 10") |
| `duration_days` | number ≥ 0 |
| `frequency` | Rarely 1, Occasionally 2, Frequently 3, Constantly 4 |
| `progression` | Better 0, Same 1, Worse 2 |
| `site` | string. general: head, chest, abdomen, back, arms, legs, other. skin: face, scalp, neck, chest, back, arms, hands, legs, feet, other. oral: teeth, gums, tongue, inner_cheek, lips, roof_of_mouth, jaw, throat, multiple_areas, other. wound: read the Kotlin `getSelectedSite` |
| `character` | Sharp 1, Dull 2, Burning 3, Throbbing 4, Cramping 5, Pressure 6 |
| `trigger` | **the number of triggers ticked** (Movement, Food, Exercise, Stress, Light, None), sent as a double. Keep this; the model was trained on it |
| `associated_symptoms`, `pre_symptoms`, `post_symptoms` | lists of strings from the checkbox containers (`getSelectedSymptoms`) |

Selecting a complaint type hides and clears the other site groups.

### Endpoints (all except `/health` need `Authorization: Bearer <supabase access token>`)
| Method | Path | Body |
|---|---|---|
| GET | `/health` | none, no auth |
| POST | `/api/v1/checkups/analyze` | JSON `{symptoms, patient}`; used when **no image** was chosen |
| POST | `/api/v1/checkups/analyze-image` | multipart: `symptoms` (JSON string), `patient` (JSON string), `image_type` (`skin`/`oral`/`wound`), `image` (file). Max 10 MB, min 32×32 px; the server resizes |
| POST | `/api/v1/assistant/chat` | JSON `{message, checkup_id?}` → `{status, message, context}` |

Errors to show nicely: 401 (log in again), 400 (bad image/JSON, show `detail`), 413 (image too large), 503 (model unavailable, show `detail`), 500. Timeouts: connect 30 s, read/write 60 s; image analysis can be slow on the first call.

### Response (`CheckupResponse`)
`status`, `assessment{image_type, finding, confidence, probabilities}`, `screening{main_concern, overall_status, screening_summary, triage, red_flags[], vitals_interpretation, model_explanations[], next_steps, overall_explanation}`, `image_result{type, prediction{class_index, class_name, confidence, probabilities}}`, `symptom_result`, `patient_result` (each `{class_index, class_name, confidence, probabilities}`), `uncertainty{confidence, uncertainty, completeness, image_quality}`. Every field can be null/missing, so parse defensively. Reference: `data/remote/ApiModels.kt`.

### Supabase tables
- `profiles(id, full_name, date_of_birth, sex, height_cm, weight_kg, created_at, updated_at)`
- `checkups(id, user_id, status, overall_score, overall_category, confidence, uncertainty, completeness, symptoms, patient_data, image_result, symptom_result, patient_result, fusion_result, screening, uncertainty_data, created_at)`
- Reads: latest = filter `user_id`, order `created_at` desc, limit 1; history = same without limit; detail = filter `id` and `user_id`. The backend (not the app) writes `checkups`.
- Date strings are ISO timestamps; format for display with `intl`.

### Auth
- PKCE flow, deep link `health360://login/reset`, which must be listed in Supabase → Authentication → URL Configuration → Redirect URLs.
- Attach the token with a dio interceptor that reads `Supabase.instance.client.auth.currentSession?.accessToken`; on a 401, call `refreshSession()` and retry once.

---

## 5. Flutter setup

**Packages:** `supabase_flutter`, `dio`, `flutter_riverpod`, `go_router`, `image_picker`, `intl`. Optional: `freezed` + `json_serializable`.

**Config** (never committed): run with
`flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=... --dart-define=API_BASE_URL=http://10.0.2.2:8000`
(10.0.2.2 reaches your PC from the Android emulator; on a real phone use your PC's LAN IP). Read them with `String.fromEnvironment`. The publishable key is safe in the client; the Supabase **secret** key must never be in the app.

**Android:** package `com.example.health360ai` (keep, or choose a new one before first release); `minSdk 26`; `INTERNET` permission in main manifest; `usesCleartextTraffic="true"` **only** in `android/app/src/debug/AndroidManifest.xml`; intent filter for scheme `health360`, host `login`; camera permission handled by `image_picker`.

```
lib/
  main.dart
  app/        router.dart, theme.dart, config.dart
  core/       api_client.dart, supabase.dart, validators.dart, formatters.dart
  data/
    models/        profile, symptoms, vitals, checkup_summary, checkup_detail, checkup_response, assistant
    repositories/  auth_repo, profile_repo, checkup_repo, assistant_repo
  state/      checkup_draft_provider.dart, auth_provider.dart
  features/   auth/ shell/ home/ patient/ symptoms/ vitals/ image/ result/ history/ assistant/ profile/
```

---

## 6. Known quirks in the Kotlin app: fix these in Flutter, do not copy them

- **Q1: profile is lost when email confirmation is on.** `RegisterActivity` calls `signUp`, then inserts into `profiles` only if a session exists. With email confirmation enabled there is no session, so it shows "Please verify your email" and **never creates the profile**. Flutter fix: send name/DOB/sex/height/weight as sign-up metadata (`data:`) and create the `profiles` row with a Supabase database trigger, or create it on first login when none exists.
- **Q2: password rules differ.** Register needs 8+ characters, reset needs 6+. Use 8+ everywhere.
- **Q3: Reset screen is built in code with `inputType = 129`;** build a proper password field with a show/hide toggle.
- **Q4: `HomeFragment` "Symptoms overview" is hard-coded "Completed".** Keep, or derive from data.
- **Q5: request/response bodies contain health data.** Never log them in release builds; never log the token.

---

## 7. Supabase checks (do these in the dashboard)

1. `checkups` and `profiles` have **Row Level Security enabled**.
2. Policies: `checkups` SELECT where `auth.uid() = user_id`; `profiles` SELECT/INSERT/UPDATE where `auth.uid() = id`. Writes to `checkups` come from the backend with the secret key, so no client INSERT policy is needed.
3. Redirect URL `health360://login/reset` is listed.
4. Decide whether email confirmation stays on (affects Q1).

---

## 8. Phases

1. **Scaffold.** `flutter create`, packages, theme from the screenshots, router with an auth guard, config, Android manifest changes.
2. **Data layer.** Models, Supabase init (PKCE), dio client with token interceptor + 401 refresh, repositories, `CheckupDraft`. Smoke test: `GET /health`.
3. **Auth.** Login, register (fix Q1), forgot/reset password via deep link, session persistence, logout.
4. **Shell, Home, Profile.**
5. **Checkup flow.** Patient → Symptoms → Vitals → Image, with the same validation and messages.
6. **Submit + Result.** Choose `/analyze` or `/analyze-image`; loading and error states; Result from a live response and from a stored row.
7. **History + Assistant.**
8. **Hardening.** HTTPS backend URL, release build, tests for validators/payload/parsing, remove debug logging.

Per-item prompt (use after the Section 0 prompt):
```
Item <N>: <name>. Kotlin files: <paths>. Read them first, then implement in ./health360_flutter following plan sections 3–6. Keep encodings and messages identical. Run flutter analyze, tick the checklist, summarise in 3 lines, then stop.
```

---

## 9. Progress checklist

- [x] 1. Flutter scaffold, theme, router + auth guard, config, Android manifests
- [x] 2. Models, Supabase client, dio client (token + refresh), repositories, `CheckupDraft`, `/health` smoke test
- [ ] 3a. Login
- [ ] 3b. Register (with Q1 fix)
- [ ] 3c. Forgot password + Reset password (deep link)
- [ ] 4a. Bottom-nav shell + Home
- [ ] 4b. Profile
- [ ] 5a. Patient info
- [ ] 5b. Symptoms
- [ ] 5c. Vitals
- [ ] 5d. Image input
- [ ] 6a. Submit (with and without image)
- [ ] 6b. Result screen (live + stored)
- [ ] 7a. History
- [ ] 7b. Assistant
- [ ] 8. HTTPS, release build, tests, cleanup

---

## 10. Not yet verified

- `ResultActivity.kt` and `PatientInformationActivity.kt` were read for structure only. Item 5a and 6b must read them line by line (formatting helpers like `formatSymptomFinding`, `formatOverallStatus` and `buildHistoricalScreening` carry display logic).
- The wound-site options and the exact BP/HR toast wording come from Kotlin files not copied here.
- How `MainActivity.kt` builds the password-reset redirect URL (confirm it uses `health360://login/reset`).
- The backend has not been run end to end. After replacing the two files, test with Postman: no token → 401; valid token → 200.
- This is a screening prototype, not a diagnostic tool. Keep the disclaimer visible in the app.
