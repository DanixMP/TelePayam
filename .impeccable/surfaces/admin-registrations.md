---
version: 1
slug: "admin-registrations"
primary_target: "backend/app/admin_panel"
related_targets: ["backend/app/modules/approvals", "frontend/lib/features/admin"]
---

# Registration review · `/admin/`

Mode: Operate. An administrator signs in with an SMS code, matches enrollment details to a pending student, and approves access. Only the super admin sees Add admin. The server owns both permissions and decisions; the queue changes after it confirms the update.

## Direction contract

- **Thesis:** Put the enrollment details and their decision together. The next registration stays within reach after each approval.
- **Own-world:** Inherit University Messenger’s navy header, blue actions, verification thread, and 48px controls from the existing system.
- **Story:** Phone → verification → pending registrations. A confirmed approval removes the row and announces the result; a stale request refreshes the queue.
- **First viewport:** The sign-in form sits beside its two steps on desktop and below them on mobile. In the queue, the pending count and student rows lead. Each row shows a university ID, program, masked National ID, and Approve action.
- **Form:** One responsive review table. At compact widths, each student’s details stack alongside their action. Names and programs support mixed directions; identifiers remain LTR.
- **Finish:** Check sign-in, queue, empty, failed, and stale states, keyboard continuity, and phone-sized reflow against the working backend using synthetic registrations.
