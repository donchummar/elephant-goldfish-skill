# Per-tenant rate limiting on the public API

**Date:** 2026-08-28
**Authors:** human + AI session
**Status:** approved

> A worked example of the four-section format, for a fictional service. The point is
> the shape and the level of detail — particularly section 4, where every file is
> named — not the subject matter. Paths and commands here are invented; yours come
> from your own project.

## 1. The problem

A single tenant can currently issue unlimited requests to the public API. Twice last
quarter one tenant's retry loop consumed enough capacity to slow responses for every
other tenant. We have no mechanism to contain this, so the current remedy is an
engineer noticing and disabling the tenant's key by hand.

Affected: all API consumers during an incident, and the on-call engineer.

Done looks like:

- Each tenant is limited to a configured requests-per-minute ceiling, defaulting to
  1000.
- Exceeding it returns `429` with a `Retry-After` header, and does not degrade other
  tenants.
- The ceiling is adjustable per tenant without a deploy.
- A tenant at 99% of its ceiling is visible on the existing API dashboard.

Explicitly not in scope: limiting internal service-to-service traffic, and per-endpoint
ceilings.

## 2. The technical plan

A token-bucket limiter in the existing API middleware chain, with bucket state in the
Redis instance the service already uses for sessions. Redis rather than in-process
state, because the service runs four replicas and per-replica counters would give each
tenant four times its ceiling.

Placed after authentication (the tenant identity is required to pick a bucket) and
before request handling (rejection should not touch business logic).

```
request
   |
   v
[ auth middleware ] --- unauthenticated ---> 401
   |
   | tenant_id
   v
[ rate limit middleware ] --- bucket empty ---> 429 + Retry-After
   |                                |
   | token consumed                 +--> metric: ratelimit.rejected{tenant}
   v
[ handler ] --> response
   |
   +--> metric: ratelimit.consumed{tenant, remaining}

bucket state: Redis key ratelimit:{tenant_id}, TTL 120s
              refill computed on read, no background job
```

Key decisions:

- **Refill on read, not on a timer.** The bucket stores a token count and a last-refill
  timestamp; tokens owed are computed at read time. No scheduler, no drift.
- **Fail open.** If Redis is unreachable the middleware admits the request and emits a
  metric. A limiter outage taking down the whole API would be a worse failure than the
  one we are preventing.
- **Ceilings live in the existing tenant settings table**, read through the settings
  cache that already has a 60-second TTL, so a change takes effect within a minute
  without a deploy.

Judged against: a tenant exceeding its ceiling is rejected within one bucket interval;
p99 latency added by the middleware stays under 2ms; a Redis outage causes no rejected
requests.

## 3. Alternatives

**Fixed-window counters.** Simpler, and one fewer stored field. Rejected: a tenant can
send two full ceilings' worth of traffic across a window boundary, which is the exact
burst profile that caused both incidents.

**A limiter at the load balancer.** No application code at all. Rejected: the load
balancer cannot see the authenticated tenant, only the source IP, and our largest
tenants share NAT egress addresses — so this would limit the wrong unit.

**In-process limiter, ceiling divided by replica count.** No Redis dependency, so no
fail-open question. Rejected: it silently breaks whenever the replica count changes,
including during a deploy, and it distributes unevenly because the load balancer is
least-connections rather than round-robin.

**Do nothing, keep disabling keys by hand.** Genuinely considered, since there have
only been two incidents. Rejected: both took over 30 minutes to diagnose, and the
manual remedy is total — the tenant loses all access rather than the excess.

## 4. Detailed implementation

| File (exact path) | Change | Notes and conventions |
|---|---|---|
| `src/middleware/rate_limit.py` | New. `RateLimitMiddleware`, token-bucket check, `429` with `Retry-After`, fail-open on Redis error. | Follows the existing middleware protocol in `src/middleware/base.py`. |
| `src/middleware/__init__.py` | Register the middleware after `AuthMiddleware`, before the router. | Order matters; assert it in the test below. |
| `src/storage/rate_limit_store.py` | New. Redis token-bucket read/consume, refill computed on read, 120s TTL. | Reuse the pool from `src/storage/redis.py`; do not open a second one. |
| `src/tenants/settings.py` | Add `rate_limit_rpm`, default 1000, read via the existing settings cache. | Nullable column, so existing tenants inherit the default. |
| `migrations/0042_tenant_rate_limit_rpm.sql` | Add the nullable `rate_limit_rpm` column. | Additive only; no backfill needed. |
| `src/observability/metrics.py` | Add `ratelimit.consumed`, `ratelimit.rejected`, `ratelimit.store_error`. | Existing counter helper and tenant label convention. |
| `dashboards/api.json` | Add a panel for tenants above 99% of ceiling. | Edit the checked-in JSON; do not hand-edit in the UI. |
| `tests/middleware/test_rate_limit.py` | New. Under limit passes; over limit gets `429` with a sane `Retry-After`; refill restores capacity; Redis failure fails open; middleware ordering. | Unit tier. |
| `tests/integration/test_rate_limit_multi_replica.py` | New. Two client instances against one Redis share a single bucket. | Integration tier; needs the Redis fixture. |
| `docs/api/errors.md` | Document the `429` and `Retry-After` contract. | Public docs — consumers read this. |

**Testing plan.** Unit tier: `make test-unit tests/middleware/test_rate_limit.py`.
Integration tier: `make test-integration` (requires `docker compose up redis`). Full
gate before review: `make lint typecheck test`. No recorded fixtures or golden files
are affected.

**Migration and rollback.** The migration is additive and nullable, so it is safe to
apply ahead of the code. The middleware reads `RATE_LIMIT_ENABLED`, defaulting to
false; ship it off, enable it in staging, then production. Rollback is the environment
variable, not a deploy. The column can stay behind harmlessly if the feature is
abandoned.

**Open questions.**

- Should the ceiling be per API key rather than per tenant? Deferred: no tenant
  currently issues more than one key, and moving the bucket key later is a small change.
- Trusted partners may need burst allowances above their steady ceiling. Deferred until
  someone asks.
