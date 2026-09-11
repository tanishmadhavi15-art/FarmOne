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
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff276749)), useMaterial3: true, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
        routerConfig: GoRouter(initialLocation: '/auth', routes: [
          GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/list', builder: (_, _) => const ListProduceScreen()),
          GoRoute(path: '/my-listings', builder: (_, _) => const MyListingsScreen()),
          GoRoute(path: '/browse', builder: (_, _) => const BrowseListingsScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/listing-detail', builder: (_, state) => ListingDetailScreen(listing: state.extra! as Listing)),
        ]),
      );
}
