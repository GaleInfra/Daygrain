# Daygrain

A private sensory field journal written in Swift and SwiftUI. Daygrain means a small grain of the day worth keeping. A five-grain bloom, warm paper, terracotta, honey, sage, rose, and lavender tie the icon to the native interface. Shared color roles give pages, cards, charts, and buttons a consistent appearance in light and dark mode. Capture sensory observations and emotion labels, connect views of a moment, organize them in personal fieldbooks, return to a detail, compare original records, and write weekly reviews that carry a focus forward. The app uses English throughout, supports iOS 15.0 and later, and opens directly to Today. There are no third-party dependencies, account screens, onboarding pages, community features, AI features, psychological diagnoses, or counseling flows.

## Open the project

1. Open `Daygrain.xcodeproj` in Xcode 15 or later.
2. Select the **Daygrain** scheme and an iPhone or iPad destination.
3. For a physical device, choose your development team and a unique bundle identifier in Signing & Capabilities.

The deployment target is **iOS 15.0**. No external packages, servers, API keys, or additional entitlements are needed. As requested, no builds or tests were run and no ZIP archive was created.

## Included features

- **Today:** date selection, warm paper overview, primary sensory and secondary emotion capture actions, actual daily note/sense totals, daily pages before secondary tasks, draft continuation, direct capture for due revisits, weekly reviews, active fieldbooks, and the next observation focus. A day that follows Today refreshes on foreground entry and significant system time changes; a deliberately selected past date stays selected.
- **Sensory notes:** smell, sound, taste, touch, and sight observations; personal notes; date and time; manually entered place; sensory intensity; up to six photos; and favorites.
- **Emotion notes:** multiple customizable emotion labels, triggering event, optional context, self-entered intensity and energy, personal notes, photos, and favorites.
- **Journal:** full-text search across note content, labels, and fieldbook names; type, favorites, photo, sense, and emotion filters; sorting; month calendar; grouped dates; and note details.
- **Connected moments:** create a sensory/emotion companion with the same title, date, place, and fieldbooks; or connect existing notes. Links are bidirectional and can be removed.
- **Fieldbooks:** create a theme, intention, focus senses, color, and icon; organize existing or new notes; view a timeline, coverage bars, and an interactive day-by-sense observation map; archive/reopen a fieldbook; compare any two notes; and export a readable fieldbook.
- **Revisits:** schedule a return to any note with your own observation question; reschedule, start early, resume an unfinished revisit, or remove the plan. Saving the new note completes the plan and links the records for comparison. Deleting the result makes the plan available again while the original remains available.
- **Weekly reviews:** select any past/current week, read its real notes, choose highlights, write a summary/detail/next focus, edit or delete a review, and carry the previous review's focus forward. Reviews do not require waiting or a minimum entry count.
- **Drafts:** debounced local autosave of note text and selected photo copies; background flush; resume new notes or unsaved edits; keep a draft or explicitly discard it. Saving a finished note removes its draft in the same database write.
- **Recently Deleted:** restore deleted notes and photo copies for 30 days; inspect deleted text; delete individual notes permanently or empty the trash. Expired notes are purged on launch, foreground entry, or opening Recently Deleted.
- **Moment kept:** saving a new note opens a contextual receipt with its actual saved record. Add/open an opposite-kind companion, plan/open a revisit, choose/open a fieldbook, inspect the moment, or finish. Existing-note edits return directly to their previous screen. This is a post-save state, not an onboarding page.
- **Editing and photos:** create/edit notes, manage fieldbook membership, remove attached copies, open a full-screen gallery, pinch to zoom, and double-tap to zoom. Fieldbook, label, revisit, and review editors protect unsaved changes on cancellation/dismissal.
- **Emotion labels:** create, rename, change color and icon, view usage counts, and delete a label without deleting its notes.
- **Insights:** whole-journal or individual-fieldbook scopes; 7-day, 30-day, 90-day, and all-time ranges; equal-duration prior-period note counts; actual counts above stacked activity columns; a five-axis sensory compass and frequency bars; label/context frequencies; self-recorded intensity/energy curves with dates and an expandable value table; fieldbook filing progress; loose-page organization; scoped revisit queues; and tap-through note collections. A compass axis uses that sense's note count divided by the number of sensory notes; the five shares are not a pie chart and need not sum to 100 percent. Prior-period comparisons shift the elapsed current interval backward by the selected number of calendar days. Open revisit totals cover any scheduled date within the chosen journal/fieldbook scope.
- **Settings:** appearance, optional local daily reminder, device authentication, app-switcher privacy cover, full JSON backup/restore with photos, readable text export, library management, and complete journal erasure.

## A complete example

1. Create a fieldbook called **After the rain**, with smell and sound as its focus.
2. Create a sensory note in that fieldbook and attach a selected photo.
3. Open the note and add an emotion companion. The records are connected automatically.
4. Plan a revisit with your own question, such as how the same place sounds in the morning.
5. Open the revisit queue and record again. Saving completes the plan; compare the original and new notes side by side.
6. Open the current week's review, select these notes as highlights, and write a next observation focus.
7. Return to Today and record from that focus, then export a readable fieldbook or a complete backup.

All steps are available immediately. Empty accounts remain empty until the user writes; no fabricated history is inserted.

## Source map

- `Daygrain/Models/JournalModels.swift`: Codable models and shared values.
- `Daygrain/Models/WorkflowModels.swift`: fieldbooks, weekly reviews, revisit plans, drafts, trash, week boundaries, and composer requests.
- `Daygrain/Services/JournalStore.swift`: atomic persistence of all workflows, reciprocal links, draft/photo retention, deletion/recovery, migration, backup validation, readable export, and restore.
- `Daygrain/Services/PhotoLibrary.swift`: iOS 15-compatible PHPicker, resized JPEG copies, and JSON file document.
- `Daygrain/Services/AppPrivacy.swift`: LocalAuthentication and authentication state.
- `Daygrain/Services/ReminderManager.swift`: repeating local notifications.
- `Daygrain/Design/`: adaptive color palette and reusable native components.
- `Daygrain/Views/FieldbooksView.swift`: fieldbook library/editor/timeline, observation map, membership management, and comparison.
- `Daygrain/Views/ReviewAndRevisitViews.swift`: weekly review library/editor and revisit planning/completion.
- `Daygrain/Views/DraftsAndTrashViews.swift`: draft recovery, Recently Deleted, and shared composer presentation.
- `Daygrain/Views/SavedMomentView.swift`: saved-record confirmation and contextual next steps.
- `Daygrain/Design/SensoryCompass.swift`: iOS 15-compatible sensory chart drawn with SwiftUI paths.
- `Brand/`: editable vector icon, preview PNG, and the visual identity notes. Raster assets for all device sizes are inside the asset catalog.
- `Daygrain/Views/`: five native tabs, note editor/details, gallery, labels, privacy, and iOS 15-compatible custom charts.
- `APP_REVIEW_NOTES.md`: an accurate review walkthrough and submission preparation notes; it is not a claim of approval.

## Local storage and backup behavior

The journal remains under Application Support/Stillnote, its original private directory name, so a branding update can open existing local data. The bundle identifier, JSON backup format identifier, and daily reminder request identifier also retain their original values for compatibility. The visible app, source folder, project, scheme, exported document names, and notification copy use Daygrain. Existing user-selected tag/fieldbook colors are preserved; new labels and covers use the warm palette. Entries and labels use atomic JSON writes. Selected photos are normalized to JPEG and resized to a maximum of 1,800 pixels on their longest edge, then stored inside the app container with iOS file protection. Photo metadata is not copied into exported JPEGs. The system Photos picker (PHPicker) needs no permission and only gives Daygrain the photos you pick. Tapping Recent Photos asks for photo library access, then shows thumbnails of your 30 most recent photos on this device; only the photo you tap is saved to the entry, and nothing is uploaded. List and grid images use downsampled thumbnails and a bounded memory cache.

Nothing is uploaded by the app. Full backup export creates JSON containing notes, labels, fieldbooks, links, revisit plans, weekly reviews, drafts, Recently Deleted, and every referenced photo copy. The user chooses the destination. Exported files are not password encrypted by Daygrain. Device backups can include app data according to iOS settings. Restore replaces the current journal after confirmation, validates schema/identifiers/references, writes new photo copies, and then atomically replaces the database. Invalid backups leave the existing journal in place. Full backup files are limited to 150 MB for export and import. Readable text export contains saved notes and weekly reviews; a fieldbook export contains its saved notes. Text exports do not embed images or restore application state.

Version-one local journals and backups are readable. New workflow collections default to empty and the next successful database write uses version two. Unsupported or unreadable databases open in recovery mode without being overwritten.

Deleting a note moves it and its photo copies into Recently Deleted. Draft, active, and deleted notes all protect their referenced photos from orphan cleanup. Permanent removal detaches links, review highlights, and affected revisit plans before removing unused photo files. The original photo library is never modified. Erasing the journal resets all journal data and labels, including drafts and trash; appearance, lock, and reminder preferences remain.

App Lock covers the existing interface in a separate native window so open editors and navigation are retained while the app is locked. Face ID, Touch ID, or the device passcode can unlock it. The app-switcher cover is applied even when App Lock is off.

All statistics are counts or arithmetic averages of the user's own records. The app contains no interpretation, diagnosis, treatment suggestions, chat, or mental-health assessment. Empty accounts show honest empty states; no sample notes are inserted.

## Delivery status

Implementation and static source review are complete for this iteration. No build, simulator launch, automated test, physical-device validation, or App Store submission was performed, per the request. Runtime behavior and distribution readiness have not been verified. Apple approval and market differentiation cannot be guaranteed by adding code; submitted binaries, original branding, metadata, support/privacy information, and actual quality still matter.
