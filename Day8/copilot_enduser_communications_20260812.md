# Copilot Support — End User Communications
**Date:** 2026-08-12  
**Prepared by:** DWP IT Support

Each section below is addressed directly to the user who raised the ticket. Share the relevant section with each person.

---

## Ticket 1 — Finance Lead: Copilot won't summarise the Q3 board pack

**Hi,**

Thanks for getting in touch. The most likely reason Copilot can't summarise that file is that it has a **sensitivity label** applied — for example, Confidential or Highly Confidential. These labels are there to protect sensitive business documents, and they can prevent Copilot from reading the content even when you yourself can open the file.

**What to do next:**

1. Open the board pack in SharePoint and look for a coloured banner near the top of the page or document — this shows the sensitivity label.
2. If a Confidential or higher label is shown, contact your IT team and let them know. They will check whether the Copilot policy for your organisation allows processing of files at that classification level.
3. If no label is shown, IT will check whether your access to the file is via a shared link, as this can also limit what Copilot can see.

You do not need to do anything else right now. IT will follow up with you directly.

---

## Ticket 2 — New Hire: Copilot in Outlook doesn't know about my emails

**Hi, and welcome to the team!**

This is completely normal for a new account. When a new mailbox is created, Microsoft 365 needs time to build an index of your emails and calendar before Copilot can use them. This process usually takes **24 to 72 hours** from when your account was first activated.

**What to do next:**

1. Check back tomorrow or the day after and try asking Copilot to summarise your recent emails again.
2. If Copilot is still not working after 72 hours, contact the IT helpdesk — it is possible your Copilot licence has not yet been assigned as part of your onboarding setup.

No action is needed on your side right now. This should resolve itself shortly.

---

## Ticket 3 — HR Manager: Copilot says "I don't have access to that content" for the salary spreadsheet

**Hi,**

The message you received is expected behaviour — it is not a fault. Salary review files are typically marked with a **high-sensitivity label** to protect personal and confidential data. When that label is applied, Copilot is deliberately blocked from reading the file, even if you have permission to open it yourself. This is a security control, not a bug.

**What to do next:**

1. Check the sensitivity label on the spreadsheet (look for a banner when the file is open in Excel or SharePoint).
2. If you genuinely need Copilot to assist with this content, raise a request with your IT team explaining the business need. They can review whether the label policy can be adjusted — this will need sign-off from your Information Security team.
3. In the meantime, you can copy the relevant data manually into a new, unlabelled Word document and ask Copilot to help with that instead.

---

## Ticket 4 — Sales Rep: Copilot can't find the client contract shared via a guest link

**Hi,**

This one comes down to how the file was shared with you. Copilot can only search and reference files that are stored **within our organisation's own Microsoft 365 environment**. A file shared via a guest link from another company lives in *their* system, not ours — so Copilot has no way to access or index it.

This is a boundary that applies to all users and is not something specific to your account.

**What to do next:**

1. Ask the external contact to send you a copy of the contract that you can save directly into your own OneDrive or a SharePoint folder in our tenant.
2. Once the file is saved in our environment, Copilot will be able to find and summarise it.
3. If you are unable to get a copy, you can still open the file manually via the guest link and read it yourself — Copilot just will not be able to reference it.

---

## Ticket 5 — IT Admin: Copilot stopped working for the whole Finance team

**Hi,**

A team-wide outage like this is unusual and we are treating it as a priority. There are two most likely causes: a **licence assignment that may have changed overnight** (for example, a group licence being removed during a scheduled reconciliation), or a **Microsoft 365 service incident** affecting our tenant.

**What is being checked:**

- IT is reviewing the Copilot licence status for all Finance team members in the Microsoft 365 Admin Centre.
- IT is also checking the Microsoft 365 Service Health dashboard for any active incidents.

**What you can do:**

1. Ask affected team members to sign out of Microsoft 365 apps and sign back in, then test Copilot again.
2. If a licence issue is confirmed, IT will re-assign licences and notify the team once access is restored.
3. If a service incident is confirmed, IT will monitor Microsoft's updates and keep the team informed of the expected resolution time.

We will update you as soon as we have more information.

---

## Ticket 6 — Manager: Copilot surfaced a file I didn't know I had access to

**Hi,**

There is no fault here — Copilot is working exactly as intended. It only ever shows you content that you have **legitimate permission to access** in Microsoft 365. If it found a file in a folder you had forgotten about, it means your account has (or had) read access to that folder.

This is worth taking as a prompt to review your access.

**What to do next:**

1. If you are comfortable with your access to that folder, no action is needed.
2. If you feel you should not have access to that folder, please raise a request with the IT team to have your permissions reviewed and adjusted. This is a routine process and there is no concern about how Copilot behaved — it was doing its job correctly.
3. Going forward, IT can review team-wide SharePoint permissions to make sure access is aligned with current role requirements.

---

## Ticket 7 — Analyst: Copilot only gives generic answers, not using our internal content

**Hi,**

When Copilot gives only general answers and does not reference our internal SharePoint documents or emails, it usually means one of two things: either the **Copilot for Microsoft 365 licence** has not been assigned to your account, or your account does not yet have access to the SharePoint sites that contain the content you need.

**What to do next:**

1. Contact the IT helpdesk and ask them to confirm whether your account has a **Copilot for Microsoft 365 licence** assigned.
2. If the licence is in place, let IT know which SharePoint sites or document libraries you need access to. They can check your current permissions and request access on your behalf if needed.
3. If your account or access was set up recently, it may also be worth waiting 24–48 hours and trying again, as new content can take time to be indexed.

---

## Ticket 8 — Executive Assistant: Copilot in Outlook can't see the shared mailbox calendar

**Hi,**

This is a known limitation of how Copilot currently works with shared and delegate mailboxes. Copilot in Outlook reads from **your own mailbox and calendar** — it does not automatically include shared mailboxes or calendars that you manage on behalf of someone else, even if you have full delegate access to them.

This is not a fault with your setup; it reflects the current scope of what Copilot can access.

**What to do next:**

1. For tasks involving your director's shared mailbox calendar, you will need to open it directly in Outlook as you normally would — Copilot cannot assist with that content at this time.
2. IT will monitor Microsoft's roadmap for updates to shared mailbox support in Copilot and will communicate any changes when they become available.
3. If you have specific tasks you were hoping Copilot could help with (such as drafting meeting summaries or scheduling), let the IT team know and they can advise on any available workarounds.

We are sorry this is not yet fully supported and appreciate your patience.

---

*For any further questions, please contact the IT helpdesk.*  
*Reference: Copilot Triage Batch — 2026-08-12*
