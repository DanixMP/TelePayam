# University Messenger Frontend

Flutter implementation of `../FRONTEND_PLAN.md`. Phases 0–7 include identity and account gating, local-first messaging, managed groups and channels, rich message actions and attachments, report-scoped moderation, university service requests and ticket chat, and LiveKit audio/video calls.

The backend now supplies the matching conversation administration, realtime message mutation, moderation review-state, service timeline/result, and persisted call-session contracts. Group calls and native closed-app incoming-call presentation remain post-v1 work.

## Run

```powershell
flutter pub get
flutter run -d windows --dart-define=DEMO_MODE=true
```

From the project root, `Rub.bat` migrates and starts the FastAPI backend on port 8000 and launches the Flutter web client in Chrome on port 3000.

With the backend connected, sign in as an administrator using the SMS code to open the **Admin panel**. It is also available from the chat navigation menu. Both admin roles can approve student registrations. Only **09981080891**, the super admin, has **Add admin** for provisioning an unregistered mobile number.

## Messaging

- **Menu → My profile**: upload or remove a JPG/PNG/WebP photo and copy your `@username` or full Messenger ID.
- **Menu → Find by ID** (also available from chat search): search a username prefix or exact ID. Select a person to open their DM; selecting a public channel or group opens its details.
- **Attach → Photo, video or file**: send up to 10 attachments with an optional caption. Tap images to zoom, tap audio/video to play, or use Download. Windows and Linux use the system media player.
- Long-press a delivered message (right-click on desktop) to **Reply** or **Forward**. Tap a quoted reply to read its original. Forwards retain captions, files and sender attribution, including when forwarded to **Saved messages**.
- **Attach → Emoji, stickers and GIFs** includes the bundled Campus Notes pack, looping GIFs, and uploads. Long-press a received sticker or GIF to favorite or save it. These features use the connected backend, not an external GIF provider.

The web build serves CanvasKit and the pinned sql.js SQLite runtime locally. Use `flutter build web --dart-define=API_BASE_URL=http://localhost:8000/api/v1` for a local web build.

The demo uses code `123456`. A phone ending in `99` follows the professor flow; other valid Iranian mobile numbers follow the student flow.

Connect to the backend:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1
flutter run -d <android-device> --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## Generate And Verify

```powershell
flutter gen-l10n
dart run build_runner build --force-jit
dart format lib test
flutter analyze
flutter test
flutter build windows --debug
flutter build apk --debug
```

`--force-jit` avoids a Dart build-hook conflict when generating Drift code with the current package set.

## Configuration

- `DEMO_MODE=true`: deterministic local identity and chat data.
- `API_BASE_URL`: REST base ending in `/api/v1`; WebSocket derives `/ws` from the same origin.
- Default Android emulator API URL: `http://10.0.2.2:8000/api/v1`.

Tokens and lightweight settings use secure storage. Account, conversation, message, draft, outbox, sticker, service request, and sync cursor data use Drift.

Android builds require access to Google's Maven repository for Android Gradle Plugin and AndroidX artifacts. Calls additionally require camera and microphone permission on-device.
