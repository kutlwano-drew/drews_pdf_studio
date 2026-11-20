# Drew’s PDF Studio

Drew’s PDF Studio is a desktop-first PDF workspace for organising, reviewing, editing and exporting PDF documents.

## Working safely

- The source PDF is kept unchanged while edits are applied to a working copy.
- Use **Undo** and **Redo** to move through applied changes.
- Use **Compare** to inspect the original and edited document side by side.
- Export a copy when you are ready to keep the result.

## Workspace

The workspace keeps document viewing central. Quick actions are available from the workspace toolbar and the command overlay. The desktop menu groups file, editing, view, tools, language, about and support actions.

## Languages

The interface includes British English, Setswana, Hindi, Mandarin Chinese and Arabic. Change the language from the menu at any time. The selected language is saved on this device.

## Privacy

PDF processing is performed locally by the application unless a feature explicitly opens an external website or download source.

## Updates

The updater reads a version index and release metadata from the configured update feed. Before publishing, configure `AppUpdateConfig.feedBaseUrl` in `lib/services/app/app_update_config.dart` and publish a `versions.txt` index plus version folders containing `release.md`, `whats_new.md` and `downloads.md`.

## Editing limitations

The current PDF engine can rearrange pages, crop pages, redact content, edit metadata and forms, and add watermarks, stamps and image-based annotations. It does not expose reliable in-place replacement of arbitrary existing PDF text runs. The app therefore does not pretend that a text overlay is a true text edit; use redaction and an annotation/stamp where appropriate.
