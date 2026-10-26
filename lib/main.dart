import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_zone;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'welcomeparent.dart';
import 'parentAcceuil.dart';
import 'sagefemmeNeo.dart';
import 'medecinacceuil.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'notificationservice.dart';
import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Initialiser les notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (inputData != null) {
      await NotificationService.afficherNotification(
        inputData['id'],
        inputData['title'],
        inputData['body'],
      );
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Fichier .env chargé avec succès !");
  } catch (e) {
    debugPrint("🚨 Erreur lors du chargement du fichier .env : $e");
  }

  await initializeDateFormatting('fr_FR', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  if (!kIsWeb) {
    // 1. WorkManager (Seulement sur mobile)
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // 2. Timezone & Notifications
    tz.initializeTimeZones();
    tz_zone.setLocalLocation(tz_zone.getLocation('Africa/Algiers'));

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'bebe_care_channel',
        'Rappels Santé Bébé',
        importance: Importance.max,
        playSound: true,
      ));
      await androidPlugin.requestNotificationsPermission();
    }
  }


  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (kIsWeb) {
    // Sur Web : On ignore l'onboarding, on va droit au but
    runApp(const TifliCareApp(showOnboarding: false));
  } else {
    // Sur Mobile : On vérifie si l'utilisateur a déjà vu l'onboarding
    bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    runApp(TifliCareApp(showOnboarding: !seenOnboarding));
  }
}

class TifliCareApp extends StatelessWidget {
  final bool showOnboarding;
  const TifliCareApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    // Détection Web ou Écran large
    bool isDesktopOrWeb = kIsWeb || MediaQuery.of(context).size.width > 600;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TifliCare',
      locale: const Locale('fr', 'FR'),
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E),
        useMaterial3: true,
      ),
      home: isDesktopOrWeb
          ? const LoginPage()
          : (showOnboarding ? const OnboardingVideoPage() : const AuthCheck()),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          return (user == null) ? const LoginPage() : AuthWrapper(user: user);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final User user;
  const AuthWrapper({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          String role = data['role'] ?? 'Parent';

          if (role == "Parent") {
            return const ParentAccueil();
          } else if (role == "Sage-femme" || role == "Néonatologue") {
            return SaggeNeo(doctorData: data);
          } else if (role == "Médecin" || role == "Vaccinateur") {
            return PediatreHome(doctorData: data);
          }
        }
        return const LoginPage();
      },
    );
  }
}