# Prevention Note

## Specific Process Change
**Control Name:** Monday 08:30 Access and Desktop Readiness Gate (ADR Gate)

Before any migrated floor enters Monday business hours, run a mandatory 3-user/3-device checkpoint at 08:30 using a fixed checklist: one sign-in path check, one desktop-icon integrity check, and one Copilot citation access-boundary check against a denied-control user. The gate owner is the release engineer, and closure requires evidence screenshots plus audit outputs attached to the change record.

**Pass Criteria:** All six checks pass (3 users + 3 devices) with no access-policy deny drift, no profile-desktop mismatch, and no unauthorized Copilot citation.

**Fail Action:** Automatic rollout hold for that floor, immediate rollback to last known-good policy/config state, and incident bridge activation before users start work.

This control would have caught the Floor 6 login policy mismatch, profile-desktop artifact issue, and Copilot access-boundary risk before Monday morning user impact.