import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  // Modèle principal puis modèles de secours si Google est surchargé (503)
  static const List<String> _models = [
    "gemini-3.8-flash",
    "gemini-3.5-flash",
    "gemini-flash-latest",
  ];

  // ---------- Âge calculé depuis la date de naissance ----------
  static DateTime? _parseBirth(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    return DateTime.tryParse(raw.toString().replaceAll('/', '-'));
  }

  static String _ageText(DateTime birth) {
    final now = DateTime.now();
    int years = now.year - birth.year;
    int months = now.month - birth.month;
    int days = now.day - birth.day;
    if (days < 0) {
      months--;
      days += 30;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    final totalMonths = years * 12 + months;
    return "$years an(s), $months mois, $days jour(s) "
        "(soit $totalMonths mois au total)";
  }

  // ---------- Contexte complet du bébé ----------
  static String _buildChildContext(Map<String, dynamic>? babyData) {
    if (babyData == null) return "";
    // Minimisation : ni prénom, ni nom, ni date de naissance exacte ne sont envoyés
    final sexe = babyData['sexe'] ?? 'Inconnu';
    final birth = _parseBirth(babyData['dateNaissance']);
    final poids = babyData['mensurations']?['poids'];
    final taille = babyData['mensurations']?['taille'];

    final buf = StringBuffer("\n\nDONNÉES DU BÉBÉ (utilise-les pour personnaliser tes réponses) :\n");
    buf.writeln("- Sexe : $sexe");
    if (birth != null) {
      buf.writeln("- Âge actuel : ${_ageText(birth)}");
    }
    final pc = babyData['mensurations']?['pc'];
    if (poids != null) buf.writeln("- Poids de naissance : $poids kg");
    if (taille != null) buf.writeln("- Taille de naissance : $taille cm");
    if (pc != null) buf.writeln("- Périmètre crânien de naissance : $pc cm");
    final alim = babyData['alimentation'];
    if (alim is Map && alim['type'] != null) {
      buf.writeln("- Alimentation déclarée à la naissance : ${alim['type']}");
    }
    buf.writeln("- Date d'aujourd'hui : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}");
    return buf.toString();
  }

  // ---------- Données suivies dans l'app (mesures, visites, repas) ----------
  static String _fmtDate(dynamic d) {
    if (d is Timestamp) {
      final x = d.toDate();
      return "${x.day}/${x.month}/${x.year}";
    }
    return d?.toString() ?? "?";
  }

  static Future<String> loadBabyContext(String babyId) async {
    final baby = FirebaseFirestore.instance.collection('babies').doc(babyId);
    final buf = StringBuffer();

    // Dernières mesures
    try {
      final snap = await baby
          .collection('measures')
          .orderBy('date', descending: true)
          .limit(5)
          .get();
      if (snap.docs.isNotEmpty) {
        buf.writeln("- Dernières mesures (la plus récente en premier) :");
        for (final d in snap.docs) {
          final x = d.data();
          buf.writeln(
              "  • ${_fmtDate(x['date'])} : poids ${x['poids']} kg, taille ${x['taille']} cm, PC ${x['pc']} cm");
        }
      }
    } catch (_) {}

    // Dernières visites médicales
    try {
      final snap = await baby
          .collection('visites')
          .orderBy('date', descending: true)
          .limit(3)
          .get();
      if (snap.docs.isNotEmpty) {
        buf.writeln("- Dernières visites médicales :");
        for (final d in snap.docs) {
          final x = d.data();
          buf.write("  • ${x['title'] ?? 'Visite'} (${x['date']}), "
              "alimentation : ${x['alimentation'] ?? '?'}");
          if ((x['conclusion'] ?? '').toString().isNotEmpty) {
            buf.write(", conclusion : ${x['conclusion']}");
          }
          if ((x['traitement'] ?? '').toString().isNotEmpty) {
            buf.write(", traitement : ${x['traitement']}");
          }
          buf.writeln();
        }
      }
    } catch (_) {}

    // Repas du jour
    try {
      final now = DateTime.now();
      final today =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final snap = await baby
          .collection('repas')
          .where('date', isEqualTo: today)
          .get();
      if (snap.docs.isNotEmpty) {
        final repas = snap.docs.map((d) => d.data()).toList()
          ..sort((a, b) =>
              (a['heure'] ?? '').toString().compareTo((b['heure'] ?? '').toString()));
        buf.writeln("- Repas d'aujourd'hui :");
        for (final r in repas) {
          buf.writeln("  • ${r['heure']} : ${r['type']} (${r['quantite']})");
        }
      } else {
        buf.writeln("- Aucun repas enregistré aujourd'hui.");
      }
    } catch (_) {}

    if (buf.isEmpty) return "";
    return "\n\nDONNÉES SUIVIES DANS L'APPLICATION :\n$buf"
        "Si une valeur te paraît impossible (par exemple un poids ou une taille "
        "incohérents pour l'âge), ne dramatise pas : demande au parent de vérifier la saisie.";
  }

  // ---------- Appel API ----------
  static Future<http.Response> _post(
      Uri url,
      String apiKey,
      Map<String, dynamic> body,
      ) {
    return http
        .post(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: jsonEncode(body),
    )
        .timeout(const Duration(seconds: 25));
  }

  // Essaie chaque modèle ; passe au suivant si surcharge (503/429/500) ou timeout
  static Future<http.Response> _postWithFallback(
      String apiKey,
      Map<String, dynamic> body,
      ) async {
    http.Response? last;
    for (final model in _models) {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent",
      );
      try {
        var r = await _post(url, apiKey, body);

        // Si l'API refuse le paramètre de réflexion, on réessaie sans
        final cfg = body["generationConfig"] as Map;
        if (r.statusCode == 400 && cfg.containsKey("thinkingConfig")) {
          cfg.remove("thinkingConfig");
          r = await _post(url, apiKey, body);
        }

        if (r.statusCode == 503 || r.statusCode == 429 || r.statusCode == 500) {
          print("Modèle $model indisponible (${r.statusCode}), essai suivant...");
          last = r;
          continue;
        }
        return r;
      } on TimeoutException {
        print("Modèle $model trop lent, essai suivant...");
      }
    }
    if (last != null) return last;
    throw TimeoutException("Aucun modèle n'a répondu");
  }

  static Future<String> sendMessage(
      List<Map<String, String>> history, {
        Map<String, dynamic>? babyData,
        String extraContext = '',
      }) async {
    try {
      final apiKey = "*******************";
      if (apiKey.isEmpty) return "Clé API manquante dans le fichier .env";

      final systemInstruction =
          "You are TifliCare AI, a professional pediatric assistant for parents in Algeria "
          "(infant nutrition, growth milestones, CNPM vaccination schedule). "
          "Follow WHO guidelines. Reply in the same language as the parent. "
          "Be concise: short paragraphs, maximum 150 words unless the parent asks for details. "
          "Refer to the baby as 'votre bébé' (you do not know its name) and adapt advice to the baby's exact age. "
          "Never give a diagnosis or prescribe medication. "
          "For emergency symptoms, tell the parent to see a pediatrician or go to the nearest "
          "emergency room immediately."
          "${_buildChildContext(babyData)}$extraContext";

      final body = <String, dynamic>{
        "system_instruction": {
          "parts": [
            {"text": systemInstruction}
          ]
        },
        "contents": history
            .map((msg) => {
          "role": msg["role"] == "user" ? "user" : "model",
          "parts": [
            {"text": msg["text"] ?? ""}
          ]
        })
            .toList(),
        "generationConfig": {
          "maxOutputTokens": 1024,
          // Réduit le temps de "réflexion" => réponse beaucoup plus rapide
          "thinkingConfig": {"thinkingLevel": "low"},
        },
      };

      final response = await _postWithFallback(apiKey, body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data["candidates"]?[0]?["content"]?["parts"] as List?;
        if (parts != null) {
          final text = parts
              .where((p) => p["thought"] != true && p["text"] != null)
              .map((p) => p["text"])
              .join();
          if (text.isNotEmpty) return text;
        }
        return "Je n'ai pas pu générer de réponse. Réessayez.";
      }

      print("Erreur API ${response.statusCode} : ${response.body}");
      return "Désolé, le service est momentanément indisponible. Réessayez.";
    } on TimeoutException {
      return "Le service met trop de temps à répondre (forte demande). Réessayez dans un instant.";
    } catch (e) {
      print("Exception : $e");
      return "Erreur de connexion. Vérifiez votre internet.";
    }
  }
}
