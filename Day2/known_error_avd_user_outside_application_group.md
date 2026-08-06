
Prompt
---------
Refere @file:prompt-library.md which contains prompt templates with examples . using Known-error prompt write a Known-error for "AVD user couldn't connect; found their account was outside the assigned application group; added them; confirmed login."

output
------
Symptom: User cannot connect to AVD; login attempt fails or is denied.

Cause: User account was not a member of the assigned AVD application group.

Scope: Individual user (to confirm whether others in the same team or role are similarly excluded).

Workaround: Add the affected user to the correct AVD application group; confirm login immediately after.

Permanent fix: Review the AVD application group membership process to ensure new or migrated accounts are correctly assigned at provisioning; audit existing group membership for any similarly affected accounts (to confirm audit scope).
