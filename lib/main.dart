import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/models.dart';
import 'providers/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/listing_screens.dart';
import 'screens/order_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final appState = AppState();
    // Firebase keeps the user signed in across app restarts. Without this,
    // an already-logged-in user was dumped back on the auth screen every
    // launch instead of going straight to /home.
    final uid = appState.authUserId;
    if (uid != null) await appState.loadProfile(uid);
    runApp(ChangeNotifierProvider.value(value: appState, child: FarmConnectApp(startLocation: uid != null && appState.user != null ? '/home' : '/auth')));
  } catch (error) {
    runApp(FirebaseStartupError(error: error));
  }
}

class FirebaseStartupError extends StatelessWidget {
  const FirebaseStartupError({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FarmConnect',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText('Firebase could not start.\n\n$error\n\nCheck lib/firebase_options.dart and Firebase Console setup.'),
            ),
          ),
        ),
      );
}

class FarmConnectApp extends StatelessWidget {
  const FarmConnectApp({super.key, required this.startLocation});
  final String startLocation;
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'FarmConnect',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff17624a), brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xfff7f8f5),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffdfe5df))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff17624a), width: 1.5)),
          ),
          cardTheme: CardThemeData(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xffe4e9e3))),
          ),
          appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Color(0xfff7f8f5), surfaceTintColor: Colors.transparent),
        ),
        routerConfig: GoRouter(
          initialLocation: startLocation,
          // Protected routes: if there's no signed-in user, bounce to /auth
          // instead of letting screens hit `context.read<AppState>().user!`
          // and crash on a null check.
          redirect: (context, state) {
            final loggedIn = context.read<AppState>().authUserId != null;
            final goingToAuth = state.matchedLocation == '/auth';
            if (!loggedIn && !goingToAuth) return '/auth';
            if (loggedIn && goingToAuth) return '/home';
            return null;
          },
          routes: [
            GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            GoRoute(path: '/list', builder: (_, _) => const ListProduceScreen()),
            GoRoute(path: '/my-listings', builder: (_, _) => const MyListingsScreen()),
            GoRoute(path: '/browse', builder: (_, _) => const BrowseListingsScreen()),
            GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
            GoRoute(
              path: '/listing-detail',
              builder: (_, state) {
                final listing = state.extra;
                // `extra` doesn't survive a browser refresh or a cold deep
                // link on web — it's in-memory only. Fall back instead of
                // crashing on the old `state.extra!` null check.
                if (listing is! Listing) return const _ListingUnavailableScreen();
                return ListingDetailScreen(listing: listing);
              },
            ),
          ],
        ),
      );
}

class _ListingUnavailableScreen extends StatelessWidget {
  const _ListingUnavailableScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Listing unavailable')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('This listing link has expired. Please open it again from Browse listings.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go('/home'), child: const Text('Back to home')),
          ]),
        ),
      );
}
