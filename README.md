# FarmConnect

Flutter + Firebase marketplace for farmers and buyers.

## Run

1. Install Android Studio and its Android SDK, then run `flutter doctor --android-licenses`.
2. Run `firebase login` and authenticate in the browser.
3. Run `flutterfire configure` from this folder and select your Firebase project.
4. Enable Email/Password Auth, Firestore, and Storage in Firebase Console.
5. Apply `firestore.rules` and `storage.rules`.
6. Run `flutter pub get` and `flutter run`.

Firebase platform configuration is intentionally not committed. `flutterfire configure` generates the required native/web options for selected platforms.

## Features

- Signup with Farmer or Buyer role stored in `users`.
- Farmers create camera-backed produce listings with unique lot IDs.
- Buyers filter listed produce, place orders, and use the mock escrow flow.
- Order states: `pending_payment`, `paid_escrow`, `delivered`, `released`, `disputed`.
# FarmOne
# FarmOne
# FarmOne_2
