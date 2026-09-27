# Heathify — Future Goals (Long-Term)

This file is separate from `ROADMAP.md` on purpose. `ROADMAP.md` covers
Phases A/B/C — the concrete path to a working, production-usable app.
This file captures **long-term, post-launch ambitions**: things worth
aiming for once the core product is stable and has real users, but that
aren't needed to ship. Nothing here should block Phase A/B/C work.

Grouped by theme; not ordered by priority or dependency.

---

## 1. AI & Recognition Quality

1. Move beyond single-photo analysis to **multi-angle photo support** (e.g. take 2 photos of a plate) to improve portion-size accuracy.
2. Let users **correct Gemini's detections** over time and feed those corrections back into prompt/model evaluation, so accuracy improves per-user and in aggregate.
3. Explore **fine-tuning or a dedicated food-recognition model** once enough labeled correction data exists, to reduce dependency on general-purpose Gemini calls.
4. Add **depth/reference-object portion estimation** (e.g. using a standard plate size or a coin in-frame) to improve quantity accuracy beyond Gemini's visual estimate alone.
5. Support **multi-item, mixed-dish recognition** (e.g. a thali or bento box) more precisely than "N separate detections."

## 2. Personalization & Health Integration

1. **Wearable integration** (explicitly deferred from the scaffold) — sync with fitness trackers for calories burned, closing the loop with calories consumed.
2. **Exercise tracking**, so Heathify can show net calorie balance, not just intake.
3. **Personalized recommendations** — suggest meals/foods based on a user's goals, history, and (with consent) dietary restrictions or health conditions.
4. **Integration with health platforms** (Apple Health, Google Fit) for a unified health picture.
5. **Adaptive goals** that adjust based on progress and logged patterns, rather than a single static daily target.

## 3. Data & Nutrition Coverage

1. **Regional/cuisine-specific food databases** — deeper coverage of underrepresented cuisines rather than a generalized global dataset.
2. **Restaurant & packaged-food partnerships** for verified, exact nutrition data (vs. estimates) on known items.
3. **Crowd-sourced food database contributions** with a moderation/verification pipeline.
4. **Ingredient-level breakdown** for home-cooked/composite dishes (e.g. "chicken curry" → chicken, oil, spices, gravy base) rather than one lump entry.

## 4. Platform & Scale

1. **Multi-platform expansion** — web app, in addition to the Flutter mobile app.
2. **Social features** — optional meal sharing, friend-based accountability, community challenges (privacy-respecting, opt-in).
3. **Multi-language support** for both the UI and Gemini prompt/response handling.
4. **Offline-first mobile experience** — queue photo analysis/meal saves when offline, sync when reconnected.
5. **B2B / enterprise tier** — e.g. white-labeled version for gyms, clinics, or corporate wellness programs.

## 5. Trust, Safety & Compliance

1. **Clinical-grade accuracy option** — a mode with tighter confidence thresholds and human-reviewable results for users who need higher precision (e.g. managing diabetes), clearly distinguished from the default "estimate" mode.
2. **Regulatory compliance review** (e.g. HIPAA-adjacent handling if health data scope expands) once the product moves toward health-condition-aware features.
3. **Data export & deletion tooling** (GDPR/CCPA-style user data rights) as the user base and data sensitivity grow.
4. **Third-party security audit** before/around any B2B or health-data-adjacent expansion.

## 6. Business & Growth

1. **Subscription/premium tier** (explicitly deferred from the scaffold) — e.g. unlimited analyses, advanced insights, ad-free.
2. **Usage-based cost modeling** for the Gemini API as the user base scales, to keep unit economics healthy.
3. **A/B testing infrastructure** for prompt changes, UI flows, and onboarding.

---

## How to Use This File

When picking up a "future goal," first check whether it's actually ready
to become a Phase A/B/C item in `ROADMAP.md` — most of these depend on
things like real user data, a validated core product, or business
decisions (pricing, partnerships) that don't exist yet. Promote an item
into the roadmap once those prerequisites are met; until then, it stays
here as a direction, not a commitment.
