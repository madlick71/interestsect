import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/interests_screen.dart';
import 'screens/login_screen.dart';
import 'screens/matches_screen.dart';

/// Lokale Entwicklung: Android-Emulator erreicht den Host über 10.0.2.2,
/// iOS-Simulator über localhost. Überschreibbar via --dart-define.
const kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://10.0.2.2:55321',
);
const kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: kSupabaseUrl,
    publishableKey: kSupabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(const InterestsectApp());
}

class InterestsectApp extends StatelessWidget {
  const InterestsectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'interestsect',
      theme: ThemeData(colorSchemeSeed: Colors.black, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) return const LoginScreen();
        return const HomeShell();
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [InterestsScreen(), MatchesScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.interests_outlined),
            selectedIcon: Icon(Icons.interests),
            label: 'Interessen',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Treffer',
          ),
        ],
      ),
    );
  }
}
