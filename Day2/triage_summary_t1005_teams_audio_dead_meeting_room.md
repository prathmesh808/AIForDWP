# Structured Triage Summary

## Ticket
- T-1005

## Summary (one line)
Teams audio is non-functional on three machines in the same meeting room, indicating likely shared room-level dependency failure (to-verify).

## Impact (who/how many/business urgency)
- Who is impacted: Users of the affected meeting room
- How many affected: Three machines confirmed in one room; user count varies by meeting usage (to-verify)
- Business urgency: High for collaboration and scheduled meetings in that room

## Known Facts
- Ticket ID: T-1005
- Application: Teams
- Symptom: Audio not working
- Scope clue: Three machines in the same meeting room are affected

## Missing Information To Gather
- Whether both microphone input and speaker output are affected (to-verify)
- Whether issue is present in Windows sound test outside Teams (to-verify)
- Whether a common audio device/peripheral/dock is shared by all three machines (to-verify)
- Whether other rooms or remote users in same meetings experience audio issues (to-verify)
- Any recent room hardware, cabling, or update changes (to-verify)

## Likely Category
- Collaboration / Teams meeting-room audio path failure (to-verify)

## First Diagnostic Step
- On one affected room machine, run a Windows audio playback/record test and a Teams test call using both room audio path and a known-good USB headset to isolate shared room hardware/path issues from Teams client issues (to-verify).
