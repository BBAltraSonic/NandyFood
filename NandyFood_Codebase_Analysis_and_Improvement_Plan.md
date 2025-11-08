# NandyFood – Codebase Analysis and Improvement Plan

Last updated: 2025-11-08
Owner: Engineering Leads
Scope: Mobile app, Supabase schema/functions, CI/CD, QA

---

## 1) Snapshot Assessment

- Architecture: Feature-based, modular; clear separation of core/shared/features.
- Domain coverage: Customers and restaurant owners mature; drivers/admin partially implemented.
- Realtime/offline: Implemented; requires conflict resolution and telemetry hardening.
- Payments: Multi-provider; needs idempotency, reconciliation, and failure-path coverage.
- Security: Strong RLS/auth model; needs automated policy tests and secrets hygiene.
- Testing: Below target overall; integration/e2e gaps; coverage gates missing.
- Observability: Crash/perf present; lacks structured logging taxonomy and SLO-based alerting.
- Web: Limited parity; maps missing; needs progressive alternatives and capability detection.
- DevEx: Many manual steps (migrations/functions). CI/CD and release automation can improve.

---

## 2) Gaps Identified

### 1. Testing and Quality
- Incomplete integration and e2e coverage of order→payment→tracking.
- No mutation testing for pricing/discount/cart flows.
- Missing golden tests for critical widgets.
- No contract tests against Supabase edge functions and DB schema.

### 2. Payments Robustness
- Idempotency and retry semantics not explicitly codified.
- Webhook delivery persistence and replay not documented.
- Reconciliation (orders vs payment provider) not automated.

### 3. Realtime + Offline Consistency
- Conflict resolution strategies not formalized per entity.
- Backoff/jitter policies not unified.
- Limited telemetry for offline→online resync failures.

### 4. Observability and SRE
- No standardized structured logs with PII redaction.
- Lack of SLI/SLOs and alert policies; no error budgets.
- Missing incident response playbooks and release rollback drills.

### 5. Security and Compliance
- RLS policy drift risk without CI policy tests.
- Secrets rotation schedule undefined; env segregation could improve.
- Data retention and deletion workflows not consolidated.

### 6. Performance and Cost
- Image strategy could be unified (formats, sizes, placeholders).
- Pagination/caching consistency across lists.
- Realtime subscription volume not governed by backpressure/rate limits.

### 7. Web Parity and UX
- Maps unsupported on web; no progressive fallback.
- Feature capability detection and user messaging not systematized.

### 8. Developer Experience
- Migrations/functions/manual scripts not integrated in CI.
- Coverage thresholds not enforced; flaky test triage absent.
- Release checklist not automated in pipelines.

### 9. Accessibility & Localization
- A11y audit missing (labels, contrast, screen readers).
- i18n pipeline not implemented; RTL not validated.

---

## 3) Goals and Success Criteria

- **Quality**: Overall coverage ≥80%; critical modules ≥90%; flaky test rate <2%.
- **Reliability**: Perceived availability 99.9%; MTTR <30 min; change failure rate <10%.
- **Payments**: PSP-success ≥99%; reconciliation mismatches = 0 per release.
- **Performance**: P95 cold start <2.5s; P95 interaction <300ms; image bandwidth ↓20%.
- **Security**: Quarterly RLS audits; secrets rotated ≤90 days; zero high-severity leaks.
- **DevEx**: CI ≤10 min; one-click staging deploy; rollback ≤5 min.
- **Web parity**: Documented deltas, with progressive alternatives for maps.

---

## 4) Phased Plan (14 Weeks)

### Phase 1: Foundations (Weeks 1–3)
**Testing**
- Add integration tests for auth→cart→checkout→payment→order tracking.
- Golden tests for checkout, order tracking, restaurant detail, cart.
- Mutation tests on promotions, taxes/fees, cart calculations.
- Add coverage report and CI gate (fail < thresholds).

**Observability**
- Introduce structured logging with PII redaction and error codes.
- Add breadcrumbs around cart updates, checkout steps, payment states, realtime events.
- Create dashboards: crash-free %, cold start, payment success/fail, network errors, order funnel.

**Security**
- RLS policy unit tests using anon/service roles for core tables.
- Secrets inventory and rotation policy; environment separation guide.

**DevEx**
- CI: format, analyze, unit+widget+integration test, collect coverage; build per flavor.
- Artifacts: test reports, coverage, build outputs.
- Codify release checklist into CI jobs and PR templates.

**Deliverables**: Baseline integration/golden/mutation tests, dashboards, CI gates, RLS tests, secrets policy.

### Phase 2: Product Hardening (Weeks 4–7)
**Payments**
- Idempotency keys; server-side confirmation; retry/backoff strategy.
- Webhook persistence, signed payload verification, replay endpoint, dead-letter queue.
- Automated reconciliation job/report; alert on mismatches.

**Offline/Realtime**
- Define conflict resolution per entity (orders, items, deliveries, favorites).
- Central retry/backoff with jitter; persistent local queue; exponential backoff.
- Telemetry for sync failures, conflict counts, resolution outcomes.

**Performance**
- Image pipeline: AVIF/WebP, responsive sizes, placeholders, prefetching.
- Standard pagination with cache policies; consistent query page sizes.
- Riverpod selectors for selective rebuilds; memoization where stable.

**Roles/Permissions**
- Permission matrix doc; CI tests preventing drift; audit logs for admin/driver actions.

**Deliverables**: Payment reliability pack, offline/realtime policy, image & pagination standards, permission CI tests.

### Phase 3: Operational Excellence (Weeks 8–10)
**SRE**
- Define SLIs/SLOs; create alert rules (payment success, crash-free, latency, error rates).
- Incident response playbook; on-call rotation; postmortem template.
- Staged rollout/canary; feature flags for risky features.

**Data & Compliance**
- Data classification, retention periods, right-to-erasure workflow.
- Backup schedule; quarterly restore drills; RPO/RTO test.

**Analytics**
- Event taxonomy for funnel; standard event shapes; privacy review.

**Deliverables**: SLOs+alerts, incident playbooks, feature flags, data governance docs.

### Phase 4: Scale & Growth (Weeks 11–14)
**Scalability**
- DB indexes review via query logs; add missing indexes; paginate hot queries.
- Realtime backpressure/rate limits and subscription lifecycle management.

**Advanced Testing**
- Contract tests for edge functions and DB schema with generated fixtures.
- Device-lab E2E smoke suite pre-release; flaky test quarantine and weekly triage.

**Web Parity & A11y/i18n**
- Progressive map fallback (static tiles/placeholders, deep links).
- A11y audit fixes; begin i18n extraction, locale switching, RTL checks.

**Deliverables**: DB optimization, contract/E2E tests, web parity fallbacks, a11y/i18n baseline.

---

## 5) Concrete Step-by-Step Implementation

### A) CI/CD and Quality Gates
1. Add coverage task and set thresholds (services 90 / providers 85 / screens 70 / overall 80).
2. Fail PRs on unmet thresholds; upload HTML coverage to CI artifacts.
3. Parallelize tests by package/suite; cache build artifacts.
4. Integrate release checklist steps as CI jobs; require green pipeline to merge to main.

### B) Integration and E2E Tests
1. Flows: sign-in → browse → add to cart → apply promo → checkout → payment confirm → order tracking.
2. Edge cases: payment timeout/retry, cancel/refund, network loss during checkout, offline→online sync.
3. Widget goldens for high-traffic screens and empty/error states.

### C) Mutation and Contract Testing
1. Apply mutation testing to pricing/promo/cart services.
2. Generate API clients/contracts for edge functions; validate payloads and error codes.
3. Schema snapshot tests; fail CI if breaking changes detected.

### D) Payments Reliability
1. Introduce idempotency keys for create/confirm payment requests.
2. Persist webhook events; signature verify; implement replay endpoint.
3. Daily reconciliation job; dashboard + alerts for mismatches.
4. Comprehensive retries with exponential backoff and bounded attempts.

### E) Realtime/Offline Strategy
1. Define conflict rules (LWW, merge, or manual resolve per entity).
2. Implement a single retry/backoff utility with jitter; instrument metrics.
3. Persist outbound queues; guarantee at-least-once with dedupe.

### F) Observability
1. Structured logs with context (user/session/order IDs), scrub PII.
2. Error taxonomy: user_error, network_error, server_error, payment_error.
3. Dashboards: payment outcomes, order lifecycle times, crash-free sessions, network error rates.
4. Alerts on SLO breaches; paging policy.

### G) Security and Secrets
1. Automated tests for RLS permissions per table/action.
2. Secrets rotation schedule; environment-scoped configuration; no secrets in repo.
3. Dependency audit cadence; track vulnerable packages.

### H) Performance Optimization
1. Image loader defaults: format, size caps, low-quality placeholders, cache.
2. List screens: pagination threshold, prefetch window, cache TTLs.
3. Riverpod selectors/memoization for hot providers; measure rebuild diffs.

### I) Web Parity
1. Capability detection; static map fallback with deep-links for navigation.
2. Document parity gaps; user messaging for unsupported features.

### J) A11y & i18n
1. Semantics labels, focus order, contrast checks, scalable text.
2. Begin string extraction; add locale switching; test RTL mirroring.

### K) Data Governance
1. Data inventory and retention; implement deletion requests.
2. Backup verification; quarterly restore exercises.

---

## 6) Owners and RACI

- **QA Lead**: Testing strategy, coverage gates, flake triage.
- **Mobile Lead**: Realtime/offline, performance, web parity.
- **Backend Lead**: Payments, webhooks, reconciliation, policy tests.
- **SRE**: Observability, SLOs, alerts, incident management, CI/CD.
- **Security**: RLS audits, secrets, dependency hygiene.
- **PM/Design**: A11y, analytics taxonomy, web parity UX.

---

## 7) Milestones

- **M1 (Week 3)**: CI gates live, integration baseline, dashboards, RLS tests.
- **M2 (Week 7)**: Payment reliability pack, offline policy implemented, perf/image standards.
- **M3 (Week 10)**: SLOs/alerts, incident playbooks, feature flags, data governance.
- **M4 (Week 14)**: DB/indexing review, contract/E2E tests, web parity fallbacks, a11y/i18n baseline.

---

## 8) Metrics to Track Continuously

- **Quality**: Coverage %, flake count, regression rate.
- **Stability**: Crash-free %, ANR rate, MTTR.
- **Payments**: Success %, refund latency, reconciliation mismatches.
- **Performance**: Cold start P95, interaction P95, image bandwidth.
- **Realtime/offline**: Sync success rate, conflict rate.
- **Ops**: Deploy frequency, change failure rate, rollback time.
- **Cost**: PSP fees, realtime bandwidth, storage growth.

---

## 9) Immediate Next Actions (This Sprint)

- Add CI coverage gates and artifact uploads.
- Implement end-to-end purchase + tracking integration test.
- Introduce idempotency + webhook persistence with replay.
- Add structured logging and payment/order dashboards.
- Write RLS policy unit tests for core tables.
- Draft SLOs for crash-free sessions and payment success; configure alerts.

---

## 10) Critical Path Dependencies

### Must Complete Before:
- **Phase 2**: Phase 1 foundations (CI gates, baseline tests, observability)
- **Phase 3**: Phase 2 hardening (payments, offline, performance)
- **Phase 4**: Phase 3 operational readiness (SLOs, incident management)

### External Dependencies:
- **Payment Provider**: Sandbox access for webhook testing
- **Google Maps**: API key quota increase for web parity testing
- **Device Lab**: Access for E2E testing across device matrix
- **Security Team**: RLS audit tools and secret management platform

---

## 11) Risk Assessment

### High Risk:
- **Payment System Changes**: High complexity, production impact
- **Database Schema Changes**: Migration complexity, potential downtime
- **Realtime Architecture**: Performance implications, data consistency

### Medium Risk:
- **UI/UX Overhaul**: User adoption, regression potential
- **Testing Strategy**: Implementation time, flaky test management
- **CI/CD Pipeline**: Build time increases, pipeline stability

### Mitigation Strategies:
- Feature flags for high-risk changes
- Comprehensive rollback procedures
- Staged rollout with canary releases
- Extensive testing in staging environment

---