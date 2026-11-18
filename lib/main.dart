import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/search_field.dart';
import 'firebase_options.dart';

// Fungsi utama aplikasi
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

// Hapus sesi login sebelumnya setiap aplikasi dimulai.
  await FirebaseAuth.instance.signOut();

  runApp(const MyApp());
}

// Root widget aplikasi
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>()!;
  }

  @override
  State<MyApp> createState() => MyAppState();
}

// State aplikasi

class MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  bool isCelsius = true;

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }

  // Membaca pengaturan yang tersimpan.
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        isDarkMode = prefs.getBool('isDarkMode') ?? false;
        isCelsius = prefs.getBool('isCelsius') ?? true;
      });
    } catch (e) {
      debugPrint('LOAD PREFERENCES ERROR: $e');
    }
  }

  // Mengubah dan menyimpan tema.
  Future<void> toggleTheme() async {
    final newValue = !isDarkMode;

    setState(() {
      isDarkMode = newValue;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', newValue);
    } catch (e) {
      debugPrint('SAVE THEME ERROR: $e');
    }
  }

  // Mengubah dan menyimpan satuan suhu.
  Future<void> setTemperatureUnit(bool value) async {
    setState(() {
      isCelsius = value;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isCelsius', value);
    } catch (e) {
      debugPrint('SAVE TEMPERATURE UNIT ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const AuthGate(),
    );
  }
}

// Widget untuk menentukan halaman berdasarkan status login
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('AUTH CONNECTION: ${snapshot.connectionState}');
        debugPrint('AUTH HAS DATA: ${snapshot.hasData}');
        debugPrint('AUTH UID: ${snapshot.data?.uid}');
        debugPrint('CURRENT USER: ${FirebaseAuth.instance.currentUser?.uid}');
        // Menampilkan status autentikasi di terminal
        debugPrint(
          'AUTH GATE: '
          'state=${snapshot.connectionState}, '
          'uid=${snapshot.data?.uid}, '
          'error=${snapshot.error}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Gagal memeriksa status autentikasi.'),
            ),
          );
        }

        if (snapshot.data != null) {
          return const SearchField();
        }

        return const LoginPage();
      },
    );
  }
}
