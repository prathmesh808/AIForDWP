Summary: Printer mapping lost for the whole 3rd floor after a Win11 upgrade, with the issue tied to logon script re-application failure.

Impact: Whole 3rd floor team affected (to confirm exact headcount), multi-user business disruption.

Known facts: Issue is printer mapping loss; scope is whole 3rd floor; timing/context is after Win11 upgrade; reported mechanism is logon script was not re-applied; script referenced the old OS drive path.

Missing info: Exact affected user count (to confirm); exact printer queue/share names (to confirm); first seen/last known good time (to confirm); whether any users/devices on 3rd floor are unaffected (to confirm); exact old vs expected drive path values in the script (to confirm).

Likely category: Post-upgrade endpoint configuration issue (logon script path dependency).

First step: Validate on an affected Win11 device whether the logon script executed and whether it still references the old OS drive path; confirm mapping failure reproduces across multiple affected users.
