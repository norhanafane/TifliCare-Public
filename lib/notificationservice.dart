import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'main.dart';

class NotificationService {

  static Future<void> afficherNotification(int id, String titre, String contenu) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bebe_care_channel',
      'Rappels Santé Bébé',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
        id,
        titre,
        contenu,
        platformDetails
    );
  }


  static Future<void> programmerRappels({
    required int idBase,
    required String titre,
    required String nomBebe,
    required DateTime datePrevue,
    required bool activePremierRappel,
    required int joursAvant,
    required bool active7Jours,
    required bool active24h,
    required int heureRappel,
  }) async {
    DateTime baseDate = DateTime(datePrevue.year, datePrevue.month, datePrevue.day);

    //rappel personalise
    if (activePremierRappel) {
      final DateTime dateRappel = baseDate
          .subtract(Duration(days: joursAvant))
          .copyWith(hour: heureRappel, minute: 35);

      await _enregistrerTacheFond(
          idBase,
          "🔔 $nomBebe : $titre",
          "Le rendez-vous de $nomBebe est dans $joursAvant jours.",
          dateRappel
      );
    }

    // Rappel J-7
    if (active7Jours && joursAvant != 7) {
      final DateTime date7j = baseDate
          .subtract(const Duration(days: 7))
          .copyWith(hour: heureRappel, minute: 35);

      await _enregistrerTacheFond(
          idBase + 1,
          "📅 $nomBebe : J-7",
          "Le rendez-vous de $nomBebe est dans une semaine exactement.",
          date7j
      );
    }

    // Rappel 24h avant (J-1)
    if (active24h) {
      final DateTime date24h = baseDate
          .subtract(const Duration(days: 1))
          .copyWith(hour: heureRappel, minute: 35);

      await _enregistrerTacheFond(
          idBase + 2,
          "⏰ Demain : $nomBebe",
          "N'oubliez pas le rendez-vous de $nomBebe ($titre) prévu demain.",
          date24h
      );
    }
  }

  static Future<void> _enregistrerTacheFond(int id, String titre, String corps, DateTime momentVoulu) async {
    final Duration delai = momentVoulu.difference(DateTime.now());


    if (delai.isNegative) return;

    await Workmanager().registerOneOffTask(
      "task_$id",
      "notificationAction",
      initialDelay: delai,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      inputData: {
        'id': id,
        'title': titre,
        'body': corps,
      },
    );
  }

  /// TEST

  static Future<void> testerNotificationImmediate() async {
    await afficherNotification(999, "✅ TifliCare Test", "Le système de notification est opérationnel !");
  }

  /// TEST
  /// délai ( 15 secondes)
  static Future<void> testerExact15Sec({
    required String titre,
    required String corps,
    required int secondes,
  }) async {

    final moment = DateTime.now().add(Duration(seconds: secondes));


    await _enregistrerTacheFond(
        997,
        titre,
        corps,
        moment
    );
  }

  static Future<void> ouvrirReglagesSamsung() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
}