# NandyFood – Comprehensive Project Analysis and Improvement Plan

Last updated: 2025-11-08  
Owner: Product & Engineering Leads  
Status: Proposed

---

## 1) Executive Summary

NandyFood is approaching production readiness with strong architecture and feature coverage. Key gaps remain in test coverage, observability, developer experience, map/web parity, payments hardening, and operational readiness (SLA/SLOs, incident playbooks). This plan prioritizes quality, reliability, and scalability without slowing feature delivery.

---

## 2) Current State Assessment

- Architecture: Clean, modular, feature-based with Riverpod and real-time via Supabase. Good separation of concerns.
- Features: Core flows implemented for customers and restaurants; drivers/admin in progress.
- Security: High maturity with RLS and auth providers. Needs periodic policy audits and secrets hygiene.
- Performance: Generally optimized; opportunities in image strategy, pagination, and offline sync consistency.
- Testing: Below targets (overall ~60%). Gaps in integration/e2e, mutation testing, and contract testing with backend.
- DevEx: Manual steps for migrations/functions; room for CI/CD automation, env handling, and reproducible builds.
- Observability: Basic Crashlytics/Perf/Analytics; needs structured logging, tracing, dashboards, and error budgets.
- Compliance & Privacy: Needs consolidated data retention, consent, and DPA/SCC readiness.
- Web: Partial parity (maps missing); define acceptable deltas and progressive enhancement strategy.

---

## 3) Key Risks

- Insufficient automated test safety net for rapid releases
- Payment edge cases and reconciliation issues
- Real-time consistency across offline/online transitions
- Manual operational processes (migrations, rollbacks, incident response)
- Limited monitoring for SLOs and error budgets
- Role/permission drift as new features ship

---

## 4) Objectives and Success Criteria

- Quality: Overall coverage ≥80%, critical services ≥90%; <0.5% crash-free sessions drop per release.
- Reliability: 99.9% app availability perception; <1% payment failure not due to PSP; MTTR <30 min.
- Security: Quarterly RLS review; secret rotation every 90 days; pass external security checklist.
- Performance: P95 app start <2.5s; P95 key interaction <300ms; image bandwidth reduced by 20%.
- Delivery: CI pipeline <10 min; staging promo to prod via single approval; rollback <5 min.
- Web parity: Define and meet “acceptable parity” checklist; ship progressive alternatives for maps.

---

## 5) Improvement Roadmap (Phased)

### Phase 1 – Foundations (Weeks 1–3)
1. Testing & Quality
   - Add integration tests for: auth → order → payment → tracking happy path
   - Add regression suite for payments (PayFast/Stripe), refunds, and timeouts
   - Introduce snapshot + golden tests for critical widgets
   - Introduce mutation testing on business logic package(s)
2. Observability
   - Standardize app logging with structured, redaction-safe logs
   - Add breadcrumbs for cart, checkout, payment, and realtime events
   - Create dashboards: crashes, cold start, network errors, payment outcomes, order funnel
3. DevEx
   - CI: format, analyze, test, coverage gate, build per flavor
   - CD: auto deploy staging on main; manual approval to production
   - Cache build artifacts; parallelize test shards
4. Security
   - Secrets management policy (no secrets in .env committed; env-specific vault)
   - RLS policy review checklist; add tests for RLS with service and anon keys
5. Documentation
   - Developer onboarding (10-min setup), runbooks for migrations and functions
   - Release checklist codified in CI and PR templates

Deliverables: CI/CD pipelines, dashboards, test baseline, security runbooks.

### Phase 2 – Product Hardening (Weeks 4–7)
1. Payments Robustness
   - Idempotent payment flows with server-side verification
   - Webhooks/edge functions retry strategy + dead-letter queue
   - Reconciliation job/report (transactions vs orders)
2. Offline/Realtime Consistency
   - Define conflict resolution and retry policies per entity
   - Background sync with exponential backoff and jitter
   - Telemetry for offline → online transition failures
3. Performance Optimization
   - Global image strategy (AVIF/WebP, sizes, placeholders, prefetch)
   - Pagination + caching policy standardization
   - Reduce over-rebuilds using Riverpod selectors + memoization
4. Role & Permissions
   - Central permission matrix; add automated policy tests
   - Admin/driver flows: authorization and audit logging
5. Web Parity Strategy
   - Progressive enhancement: static map tiles or placeholder UX
   - Capability detection and graceful feature downgrades

Deliverables: Payment reliability pack, offline/realtime policy, performance changes, role policy tests, web parity plan.

### Phase 3 – Operational Excellence (Weeks 8–10)
1. SRE Readiness
   - Define SLIs/SLOs, alerting, paging policy, error budgets
   - Incident response playbook; blameless postmortem template
   - Release train with canary users and staged rollout
2. Data & Compliance
   - Data classification, retention, and deletion workflows
   - Consent management and privacy notice surfacing
   - Backups and restore drills; test RPO/RTO
3. Analytics & Experimentation
   - Event taxonomy; conversion funnel instrumentation
   - Remote config/feature flags; gradual rollout for risky features
4. Accessibility & Localization Prep
   - A11y audit: semantics, contrast, large text, screen reader
   - i18n pipeline: extraction, fallbacks, RTL readiness checklist

Deliverables: SLOs/alerts, incident playbooks, data governance docs, a11y/i18n baselines.

### Phase 4 – Scale & Growth (Weeks 11–14)
1. Scalability
   - Database indexes review; slow query log triage
   - Rate limiting and backpressure for realtime subscriptions
2. Advanced Testing
   - Contract tests with backend schemas/functions
   - End-to-end device lab runs; smoke tests pre-release
3. Feature Acceleration
   - Template repo or project generator for new features
   - Shared UI library catalog with usage guidelines
4. Cost & Performance Review
   - Track PSP fees, realtime bandwidth, storage; monthly cost report
   - Optimize hotspots identified in perf dashboards

Deliverables: DB optimization, contract/E2E tests, component catalog, cost governance.

---

## 6) Detailed Implementation Steps

A) Testing
- Add integration tests for end-to-end purchase and delivery tracking
- Add widget golden tests for critical screens
- Mutation tests on pricing, promotions, and cart logic
- Coverage gate in CI: block if < target; nightly full coverage report

B) Payments
- Edge function verification; idempotency keys; retries with backoff
- Persistent webhook delivery logs; replay endpoint
- Admin reconciliation view; alerts for mismatched states

C) Realtime & Offline
- Define entity-level sync rules (orders, order_items, deliveries)
- Local queue with persist + retry; telemetry for drops/conflicts
- Backoff policies centralized; additive jitter to avoid thundering herd

D) Observability
- Structured logs with PII redaction
- Standard error taxonomy and user-impact tags
- Dashboards: performance, errors, payments, order lifecycle; alerts on SLO breaches

E) Security
- Secrets via environment vaults per environment
- RLS unit tests for each table/action; least-privilege service roles
- Regular dependency audit and update cadence

F) DevEx & CI/CD
- Pipelines: format → analyze → test → coverage → build → upload artifacts
- Staging deploy on main; prod with approval and changelog
- Automated migrations in CI; rollback scripts and preview plans

G) Web Parity
- Capability detection; swap live maps for static previews on web
- Document parity gaps and user messaging; track as tech debt items

H) Accessibility & Localization
- Semantics and labels pass; contrast tests integrated in CI screenshots
- Extract strings; locale switcher; RTL layout checks

I) Data Governance
- Data inventory; retention periods; right-to-erasure workflow
- Backup verification job; quarterly restore game day

---

## 7) Ownership & RACI

- QA Lead: Testing strategy, coverage gates
- Mobile Lead: Performance, offline/realtime
- Backend Lead: Payments, webhooks, reconciliation
- SRE/Platform: Observability, SLOs, incidents, CI/CD
- Security: RLS audits, secrets, dependency hygiene
- PM/Design: Web parity UX, accessibility, analytics taxonomy

---

## 8) Milestones & Checkpoints

- M1 (Week 3): CI/CD live, baseline integration tests, dashboards, secrets policy
- M2 (Week 7): Stable payments, offline policy implemented, perf improvements, role tests
- M3 (Week 10): SLOs/alerts, incident playbooks, data governance, a11y/i18n baseline
- M4 (Week 14): DB scaling, contract/E2E tests, component catalog, cost report

---

## 9) Metrics to Monitor

- Quality: coverage %, flaky tests count, regression rate
- Stability: crash-free sessions, ANR rate, MTTR
- Payments: success rate, refund latency, reconciliation mismatches
- Performance: cold start P95, UI interaction P95, image bandwidth
- Realtime/offline: resync success rate, conflict rate
- Ops: deploy frequency, change failure rate, rollback time
- Costs: monthly PSP fees, data egress, storage growth

---

## 10) Risks & Mitigations

- Tight timelines vs depth of hardening → phase work, protect focus time
- Third-party outages → circuit breakers, retries, status page checks
- Drift in permissions → policy tests in CI, approval gates for schema changes
- Flaky tests slowing CI → quarantined suite, flake triage weekly

---

## 11) Next Actions (This Sprint)

- Set up CI coverage gates and artifact uploads
- Add end-to-end purchase + tracking integration test
- Create payment webhook replay + reconciliation report
- Implement structured logging and add key dashboards
- Draft SLOs for crash-free sessions and payment success
- Document migration and rollback runbooks

---
