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
<<<<<<< HEAD
    runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const FarmConnectApp()));
=======
    final appState = AppState();
    // Firebase keeps the user signed in across app restarts. Without this,
    // an already-logged-in user was dumped back on the auth screen every
    // launch instead of going straight to /home.
    final uid = appState.authUserId;
    if (uid != null) await appState.loadProfile(uid);
    runApp(ChangeNotifierProvider.value(value: appState, child: FarmConnectApp(startLocation: uid != null && appState.user != null ? '/home' : '/auth')));
>>>>>>> 7c071d1421e496099bdd5c1308300f72eaf8f22e
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
<<<<<<< HEAD
  const FarmConnectApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'FarmConnect',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b4d), brightness: Brightness.light),
          scaffoldBackgroundColor: const Color(0xfff4f7f1),
          fontFamily: 'Trebuchet MS',
          appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, backgroundColor: Color(0xfff4f7f1)),
          cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)), side: BorderSide(color: Color(0xffdce7dc))),),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xffcbd8cc))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xffcbd8cc))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xff176b4d), width: 2)),
          ),
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),),
        ),
        routerConfig: GoRouter(
          initialLocation: '/auth',
          refreshListenable: context.read<AppState>(),
          redirect: (_, state) {
            final app = context.read<AppState>();
            if (app.loading) return null;
            if (app.user != null && state.uri.path == '/auth') return '/home';
            if (app.user == null && state.uri.path != '/auth') return '/auth';
            return null;
          },
          routes: [
          GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/list', builder: (_, _) => const ListProduceScreen()),
          GoRoute(path: '/my-listings', builder: (_, _) => const MyListingsScreen()),
          GoRoute(path: '/browse', builder: (_, _) => const BrowseListingsScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/listing-detail', builder: (_, state) => ListingDetailScreen(listing: state.extra! as Listing)),
=======
  const FarmConnectApp({super.key, required this.startLocation});
  final String startLocation;
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'FarmConnect',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff276749)), useMaterial3: true, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
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
>>>>>>> 7c071d1421e496099bdd5c1308300f72eaf8f22e
          ],
        ),
      );
}
<<<<<<< HEAD
=======

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
>>>>>>> 7c071d1421e496099bdd5c1308300f72eaf8f22e
