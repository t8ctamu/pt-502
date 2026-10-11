# Help and training upkeep

The app serves `/help`, `/help/member`, `/help/officer`, and `/help/system`.
Member help is public so sign-in problems do not lock users out of instructions.
Officer and system guides require an Admin or Manager account. They do not require
profile completion, so a new officer can still read setup instructions.

The member and officer templates contain app training only. The system guide is
the standalone `docs/system-guide.html`, rendered by HelpController and readable
offline before installation. Update that single file for system instructions.

For each feature PR:

1. Review the changed page and its labels as a Member, Admin, and Manager where
   relevant. Check the actual routes, validation, and failure behavior.
2. Update the matching guide steps, troubleshooting entry, and training exercise.
   Do not describe planned or unmerged features as available.
3. Refresh affected screenshots in `app/assets/images/help/` using fictional
   accounts and events in a local or staging test environment. Use a 1280 × 900
   viewport for forms, and a wider view for a table that needs it; capture the
   actual page, with no private account or production data.
   Keep the filenames below so the view partials continue to find them.
4. Update the checked dates in the help templates and system guide. Review current
   Heroku prices and source links when hosting plans or procedures change.
5. Run `bundle exec rspec spec/requests/help_spec.rb` for role boundaries, routes,
   anchors, and screenshots, then the normal CI suite. Click the nav and contents
   links in Chrome and inspect the guides at desktop and phone width.
6. Open the standalone system guide offline. Rehearse hosting, backup/restore,
   and compatible release rollback in staging when those procedures change.
   Do not claim a production operation was verified if only local tests ran.

| Screenshot | Current feature |
| --- | --- |
| sign-in.jpg | Returning and new member sign-in |
| profile.jpg | Profile fields and phone consent |
| member-home.jpg | Points, type minimums, dues, and request status |
| event.jpg | Event details and calendar actions |
| check-in.jpg | Member location check-in |
| submission.jpg | Outside-event submission form |
| submission-status.jpg | Pending, approved, and denied submission status |
| members.jpg | Member and officer tables, dues, points, and role buttons |
| officer-profile.jpg | Officer profile editing |
| event-form.jpg | Event creation and venue configuration |
| event-check-in.jpg | Event radius, attendance points, and point type |
| qr.jpg | Event check-in QR code and link |
| attendance.jpg | Officer attendance list |
| requests.jpg | Pending approval and denial controls |
| requirements.jpg | Manager point requirements and types |

For learner training, use the exercises at the end of each guide. Have the learner
do the task and explain the result, including the error/retry behavior. Do not
practice awards, approvals, role changes, or deletion on real member records.
