# StudyBuddy (Flutter + Firebase)

Dit is een MVP-template voor jouw app (timer + overzicht + vrienden + push bij start studeren, zonder leaderboard), conform je Firestore-structuur.

## Wat zit erin
- **UI**: 3 schermen via bottom tab bar (Timer / Overzicht / Vrienden)
- **Timer**: start/pauze/stop + sessie naar Firestore
- **Overzicht**: dag/week/maand aggregaties + **afgeronde bar chart** (fl_chart)
- **Sociaal**: vrienden toevoegen via e-mail, real-time “wie studeert nu”
- **Push**: Cloud Function die vrienden notifiet bij `isStudying: false → true` + schrijft in-app meldingen
- **Login**: Google + e-mail/wachtwoord

## Vereisten
- Flutter (stable)
- Firebase project (Android + iOS indien gewenst)
- Firestore + Authentication + Cloud Messaging
- Firebase Functions (Node 18)

## Integratie in jouw Flutter-project
Je gaf aan dat je al:
- Flutter-project hebt aangemaakt
- Firebase SDK gekoppeld
- Android build geconfigureerd

Gebruik deze template als volgt:
1. Kopieer de map `lib/` en `pubspec.yaml` naar jouw project (of merge).
2. Voeg dependencies toe in `pubspec.yaml` en draai:
   ```bash
   flutter pub get
   ```
3. Zorg dat `android/app/google-services.json` aanwezig is.
   - Ik leverde een voorbeeldbestand aan in deze chat; kopieer die naar je projectpad.
4. Android Gradle:
   - `android/build.gradle`: classpath `com.google.gms:google-services`
   - `android/app/build.gradle`: `apply plugin: 'com.google.gms.google-services'`
5. Firestore rules (MVP): laat gebruikers enkel hun eigen sessions schrijven, en users lezen.

## Firestore model
Gebruikt:
- `users/{uid}`: `{name, email, friends: [uid], isStudying, currentSessionStart, fcmToken}`
- `sessions/{uid}/items/{sessionId}`: `{start, end, duration}`
- `notifications/{uid}/items/{id}`: `{title, body, createdAt, type, friendUid}`

## Cloud Function voor push
1. In Firebase CLI:
   ```bash
   cd functions
   npm i
   firebase deploy --only functions
   ```
2. De function luistert op updates in `users/{uid}`.
   - Wanneer `isStudying` naar `true` gaat, stuurt hij push naar tokens van vrienden.

## Build APK
In je eigen omgeving:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## Opmerking
Deze containeromgeving heeft geen Flutter/Android SDK, dus ik kan hier geen APK compileren. De code en Functions zijn wel volledig aangeleverd zodat je lokaal direct kunt bouwen.
