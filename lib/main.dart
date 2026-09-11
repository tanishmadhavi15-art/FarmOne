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
    runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const FarmConnectApp()));
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
          ],
        ),
      );
}
