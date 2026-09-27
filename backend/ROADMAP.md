# Heathify — Roadmap

This roadmap picks up where the backend foundation (this repo) leaves
off. It's organized into three phases that can run partly in parallel
once Phase B's early steps are done, since the frontend needs a stable
API to build against.

- **Phase A — Features to add**: product capabilities not yet in the scaffold.
- **Phase B — Backend**: the engineering work needed to support Phase A and go to production.
- **Phase C — Frontend**: the Flutter mobile app.

Each phase is broken into ordered steps. Steps within a phase are
numbered in the order they're most naturally tackled, but later steps
don't strictly require every earlier one to be "done" — treat the
numbering as a sensible default sequence, not a hard gate.

---

## Phase A — Features to Add

Product-level capabilities beyond the current analyze/save/view scaffold.

1. **User accounts & authentication**
   Real signup/login (email+password to start, social login later), replacing the placeholder `X-User-Id` header.

2. **Editable meal analysis before saving**
   Let the user adjust detected food names, quantities, or units in the analysis result before it's saved as a meal (the API already returns editable fields — this is the UX/flow around it).

3. **Manual meal entry**
   Let a user log a meal without a photo — search the food database and enter quantities directly.

4. **Daily & weekly nutrition summaries**
   Aggregate a user's meals by day/week; show totals vs. personal goals.

5. **Personal nutrition goals**
   Let users set daily calorie/macro targets and track progress against them.

6. **Meal history & editing**
   Browse past meals by date, edit or delete previously saved entries.

7. **Favorites / quick-add meals**
   Let users save frequently-eaten meals or foods for one-tap re-logging.

8. **Expanded food database**
   Move beyond the seed list to a broad, searchable food catalog (see Phase B step 3).

9. **Barcode scanning** (stretch)
   Scan packaged food barcodes as an alternative to photo analysis.

10. **Notifications / reminders** (stretch, explicitly deferred from the scaffold)
    Meal-logging reminders, daily summary notifications.

---

## Phase B — Backend

Engineering work to support Phase A and harden the scaffold for production.

1. **Real authentication**
   Implement JWT issuing/verification (`app/core/security.py` already has TODOs marking exactly where this goes), password hashing, and signup/login endpoints. Replace `get_current_user_id`'s header-trust logic with real token decoding.

2. **Authorization**
   Enforce that a user can only read/edit/delete their own meals; add ownership checks to the meals routes.

3. **External nutrition database integration**
   Replace/extend the local seed `Food` table with a real source (e.g. USDA FoodData Central, Edamam, or a licensed dataset). Keep `NutritionService`'s interface stable so this is a swap, not a rewrite.

4. **Fuzzy food-name matching**
   Replace the synonym table in `nutrition_service.py` with fuzzy matching (e.g. `rapidfuzz`) or embedding-based similarity search, per the TODOs already in that file.

5. **Object storage for images**
   Store uploaded photos in S3/GCS/Cloud Storage instead of treating `image_url` as an opaque string; return signed URLs for retrieval.

6. **Goals & summaries endpoints**
   New models/endpoints for user nutrition goals and daily/weekly aggregation (supports Phase A steps 4–5).

7. **Rate limiting**
   Protect `/analysis/analyze` in particular, since it triggers a paid external Gemini call per request.

8. **Unit conversion**
   Handle quantity units beyond "same unit as the Food row" (e.g. converting "1 piece" or "1 cup" to grams) — currently a documented limitation in `nutrition_service.py`.

9. **Audit logging & observability**
   Structured logging, request tracing, and basic metrics (latency, Gemini error rate, unmatched-food rate).

10. **CI/CD & deployment**
    Automated test/lint pipeline on push, containerized deploy to a real environment (e.g. ECS/Cloud Run), managed Postgres, secrets management for `GEMINI_API_KEY`.

11. **Load & cost testing for Gemini calls**
    Understand latency and per-request cost at expected volume before opening the analyze endpoint to real traffic.

---

## Phase C — Frontend (Flutter)

The mobile app that consumes this API. Not started in this repo.

1. **Project setup**
   Initialize the Flutter project, choose state management (e.g. Riverpod/Bloc), set up API client pointing at this backend's `/api/v1` routes.

2. **Auth screens**
   Signup/login UI wired to Phase B step 1's endpoints; secure token storage on-device.

3. **Camera & photo upload flow**
   Capture a photo or pick from gallery, upload to `POST /api/v1/analysis/analyze`, show a loading state during the Gemini round-trip.

4. **Analysis review screen**
   Display detected foods, quantities, and estimated nutrition; let the user edit an item or remove it before saving (supports Phase A step 2).

5. **Save/meal-type selection**
   Let the user pick meal type (breakfast/lunch/dinner/snack) and confirm save via `POST /api/v1/meals`.

6. **Meal history screen**
   List past meals (`GET /api/v1/meals`), tap into detail (`GET /api/v1/meals/{id}`), support edit/delete.

7. **Manual food search & entry**
   UI for `GET /api/v1/nutrition/foods/search` to support Phase A step 3.

8. **Daily/weekly dashboard**
   Charts and summaries once Phase B step 6 ships.

9. **Goals UI**
   Set and view progress against personal nutrition targets (Phase A step 5).

10. **Polish & offline handling**
    Loading/error states for network failures, image-upload retries, empty states, basic accessibility pass.

---

## Suggested Sequencing

A reasonable path through all three phases, respecting dependencies:

```
B1 (auth) ──► B2 (authorization) ──► C2 (auth screens)
B3 (real food DB) ──► B4 (fuzzy matching) ──► A8
C1 (setup) ──► C3 (camera/upload) ──► C4 (review) ──► C5 (save)
                                                    └─► A2, A3
B6 (goals/summaries) ──► A4, A5 ──► C8, C9
B7 (rate limiting) ──► B10 (CI/CD) ──► production launch
```

Everything not called out above (A6, A7, A9, A10, B5, B8, B9, B11, C6, C7, C10) can slot in wherever capacity allows — none of them block the core "photo → estimate → save → view" loop.
