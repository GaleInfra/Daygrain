# Daygrain — review notes draft

Daygrain is a native, offline sensory field journal. It is designed around repeated observation: collect sensory details and self-chosen emotion labels, organize observations into a fieldbook, revisit a specific detail, compare original records, and write a personal weekly review. It has no login, paid unlock, backend, community, AI analysis, diagnosis, or counseling feature.

## Suggested App Review notes

All core features work with locally entered content. No demo credentials or external service are required. The interface is in English and the deployment target is iOS 15.0.

To explore the connected workflow:

1. In **Fieldbooks**, create a fieldbook. Add a name, an observation intention, and focus senses.
2. Open the fieldbook and choose **New note → Sensory note**. Enter a title and an observation, optionally choose photos, and save. The **Moment kept** receipt confirms the actual saved record and offers companion/revisit/fieldbook actions, or **Done for now** to return. Its coverage bars and day-by-sense observation map use these actual records.
3. Open that note and choose **Add an emotion companion**. Select emotion labels and save. Both records now link to one another and retain the same initial date, place, and fieldbook membership.
4. Open the original note and choose **Plan a revisit**. Write an observation question and choose a date.
5. Open **Today → Revisit queue** and choose **Record a revisit**. The revisit can be started immediately, including before the scheduled date. Save the new note, switch to **Completed**, and open **Compare original & revisit**. Side-by-side details contain the user's original text and recorded values; there is no generated interpretation.
6. In **Today**, open the current weekly review. Highlight notes, enter a summary and next observation focus, and save. The focus appears on Today and can start the next note. **Fieldbooks → Weekly reviews** also opens the review library and past weeks.
7. Close an unfinished note using **Keep draft**. Resume it through **Today**, **Journal → Drafts**, or **Settings → Drafts**. Selected photo copies are retained with the draft.
8. Move a note to Recently Deleted, then restore it in **Settings → Recently Deleted**. Saved notes, drafts, and deleted notes retain their referenced photo copies.
9. **Settings → Export full backup** saves all journal data and referenced photo copies in JSON. **Export readable journal** saves a plain text document. Individual fieldbooks also support readable export. Restore is explicit and replaces local journal data after confirmation.

Insights support whole-journal/fieldbook scopes, time ranges, equal-duration prior-period counts, a five-axis sensory compass, source-value tables, filing progress, loose-page organization, and tap-through note collections. The compass uses sensory-note frequencies, and the recorded-level chart uses self-entered values. App Lock, when enabled by the user, supports device authentication. The photo picker receives only selected images. Daily reminders are local and optional.

There are no time gates, hidden reviewer modes, fabricated user records, required waiting periods, or server-controlled features.

## Submission preparation — not claims of completed work

- This code has not been built or tested on a simulator or device in this delivery. Supply actual device/OS validation results before submission; do not state that testing occurred unless it did.
- Use the actual release binary for screenshots and preview material. Do not use invented activity or metrics as evidence of real usage.
- Provide the publisher's real support contact and published privacy-policy/support URLs. Those identities and destinations were not supplied in this workspace and must not be invented.
- Review final privacy disclosures against the release binary. The current source has no network upload or analytics service; system backups and user-chosen export destinations are distinct from an app-operated sync service.
- Full JSON backups currently have a 150 MB limit. There is no automatic cloud synchronization. App Lock uses local device authentication; exported backup files are not password encrypted by this app.
- Use original and properly cleared branding and assets. The name's market availability and trademark status were not established by this implementation.
- Evaluate this app alongside the publisher's other submissions. The work here does not establish whether a similar binary, concept, or metadata has already been submitted elsewhere.

## Relevant Apple guidance

[App Review Guidelines, Design](https://developer.apple.com/app-store/review/guidelines/#design): guideline 4.2 concerns adequate utility and lasting value; 4.2.6 addresses commercialized templates/app-generation services; 4.3 addresses duplicate and indistinguishable submissions. There is no stated minimum number of minutes a reviewer must spend using an app. Added screens and source volume alone do not establish compliance or approval.
