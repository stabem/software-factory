# Lessons Learned

> Append-only. Never delete, only add. Review at the start of every work session.

---

## Sub-Agent Coordination

### File ownership conflicts
- **Problem:** Two parallel sub-agents modified the same Go file. One introduced a type assertion bug that broke the other's work.
- **Lesson:** Parallel agents must have zero file overlap.
- **Rule:** One file owner per agent. If two agents need the same file, sequence them.

### "Done" doesn't mean done
- **Problem:** Sub-agent reported task complete, but the build had compilation errors.
- **Lesson:** Sub-agents will say "done" based on writing the code, not running it.
- **Rule:** Every sub-agent spec must end with exact build + smoke test commands. No exceptions.

---

## Testing & Verification

### Localhost vs production
- **Problem:** Feature worked on localhost:8082 but failed on production domain. Cloudflare Pages SPA catch-all was intercepting API routes.
- **Lesson:** The production path includes CDN, reverse proxy, DNS, and SPA routing — all of which can silently break things.
- **Rule:** E2E tests MUST hit the actual production URL. Never just localhost.

### Missing API response fields
- **Problem:** Frontend checked `user.email_verified` but backend `UserResponse` struct didn't include the field. Value was always `undefined`.
- **Lesson:** Don't assume the API response matches what the frontend expects. Check the actual response struct.
- **Rule:** When adding frontend logic that depends on a field, verify the backend actually returns it.

---

## Investigation

### Root cause vs symptom
- **Problem:** Assumed users weren't converting due to bad onboarding UX. Real cause: 49% couldn't verify email (token generated but never emailed) → 403 on ALL API calls.
- **Lesson:** Without data, you'll fix the wrong problem. 10 minutes of DB queries saved days of wasted UX work.
- **Rule:** ALWAYS query DB + check logs before planning any fix.

---

## Infrastructure

### Cache invalidation after state changes
- **Problem:** User verified email → DB updated → but Redis cache (5min TTL) still served old `email_verified=false` → user stayed blocked.
- **Lesson:** Any mutation that changes auth-relevant state must invalidate caches.
- **Rule:** After state changes affecting auth (email verify, role change, plan upgrade) → invalidate user cache immediately.

### SPA routing intercepts API paths
- **Problem:** Email verify link pointed to `getcontentapi.com/api/v1/auth/verify` but Cloudflare Pages SPA catch-all served `index.html` instead of proxying to the backend.
- **Lesson:** SPAs with `/* → index.html` will catch API paths unless explicitly excluded.
- **Rule:** Always add `_redirects` or proxy rules for API paths. Use a separate API subdomain as fallback.
