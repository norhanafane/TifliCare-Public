import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// --- FONCTION ENVOI EMAIL AUTOMATIQUE
Future<void> _sendEmailAutomatique(String email, String pass, String code) async {
  final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '******';
  final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '*****';
  final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '*****';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'https://tiflicare-d0bc7.web.app',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': email,
          'user_password': pass,
          'activation_code': code,
        },
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("Email envoyé avec succès !");
    } else {
      debugPrint("Échec de l'envoi : ${response.body}");
    }
  } catch (e) {
    debugPrint("Erreur lors de l'envoi de l'email: $e");
  }
}

class TifliCareAdminApp extends StatelessWidget {
  const TifliCareAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007BFF)),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  // 1. On déclare la variable en premier
  final String adminId;

  // 2. On l'inclut dans le constructeur avec une valeur par défaut
  const AdminDashboard({super.key, this.adminId = "ADMIN_GENERAL"});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool isSidebarExpanded = true;
  // Index pour gérer l'affichage sur PC : 0 = Créer, 1 = Liste des utilisateurs, 2 = Suppressions
  int _currentNavIndex = 0;

  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
  }

  final Color primaryBlue = const Color(0xFF4CB8C4);
  final Color secondaryBlue = const Color(0xFF2196F3);
  final Color darkBlue = const Color(0xFF1A237E);
  final Color bgGrey = const Color(0xFFF4F7FA);

  bool _consentementRGPD = false;

  String selectedRole = 'Parent';
  final List<String> roles = ['Parent', 'Sage-femme', 'Néonatologue', 'Médecin', 'Vaccinateur'];
  final _emailParentController = TextEditingController();
  final _nomMereController = TextEditingController();
  final _prenomMereController = TextEditingController();
  final _dobMereController = TextEditingController();
  final _ssMereController = TextEditingController();
  String? gsMere, rhMere;

  final _nomPereController = TextEditingController();
  final _prenomPereController = TextEditingController();
  final _dobPereController = TextEditingController();
  final _ssPereController = TextEditingController();
  String? gsPere, rhPere;

  final _persoHistoryController = TextEditingController();
  final _famHistoryController = TextEditingController();

  // --- CONTROLLER PROFESSIONNELS ---
  final _nomProController = TextEditingController();
  final _prenomProController = TextEditingController();
  final _telProController = TextEditingController();
  final _emailProController = TextEditingController();

  bool agglutinines = false;
  bool consanguin = false;
  bool radiations = false;
  bool medicaments = false;
  bool tabac = false;

  final Map<String, String> _errors = {};

  // Générateurs
  String _generateProID() => "PRO-${DateTime.now().year}-${Random().nextInt(999).toString().padLeft(3, '0')}";
  String _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    return List.generate(12, (i) => chars[Random().nextInt(chars.length)]).join();
  }
  String _generateActivationCode() => "BABY-${List.generate(4, (i) => 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789'[Random().nextInt(33)]).join()}-${List.generate(4, (i) => 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789'[Random().nextInt(33)]).join()}";


  bool _validateForm() {
    _errors.clear();
    if (selectedRole == 'Parent') {
      if (_emailParentController.text.trim().isEmpty) _errors['emailParent'] = 'Email obligatoire';
      if (!_isValidEmail(_emailParentController.text.trim())) _errors['emailParent'] = 'Email invalide';
      if (_nomMereController.text.trim().isEmpty) _errors['nomMere'] = 'Nom obligatoire';
      if (_prenomMereController.text.trim().isEmpty) _errors['prenomMere'] = 'Prénom obligatoire';
      if (_dobMereController.text.trim().isEmpty) _errors['dobMere'] = 'Date obligatoire';
      if (gsMere == null) _errors['gsMere'] = 'GS obligatoire';
      if (rhMere == null) _errors['rhMere'] = 'Rh obligatoire';
    } else {
      if (_nomProController.text.trim().isEmpty) _errors['nomPro'] = 'Nom obligatoire';
      if (_telProController.text.trim().isEmpty) _errors['telPro'] = 'Téléphone obligatoire';
      if (_emailProController.text.trim().isEmpty) _errors['emailPro'] = 'Email obligatoire';
    }

    if (_errors.isNotEmpty) {
      setState(() {});
      _scrollToFirstError();
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez corriger les champs en rouge"), backgroundColor: Colors.red),
      );
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 10950)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _imprimerFicheAcces(String email, String pass, String code, String role) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueAccent, width: 5),
              borderRadius: pw.BorderRadius.circular(0),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("TIFLICARE", style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 5),
                      pw.Text("Carnet de Santé Numérique", style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                      pw.SizedBox(height: 15),
                      pw.Divider(thickness: 2, color: PdfColors.grey400),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text("Information de compte d'accès ", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                pw.SizedBox(height: 30),

                pw.Text("Rôle :", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                pw.Text(role, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 20),

                pw.Text("Email :", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                pw.Text(email, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),

                // Pour les professionnels uniquement : afficher le mot de passe
                if (role != 'Parent') ...[
                  pw.Text("Mot de passe :", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                  pw.Text(pass, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  pw.SizedBox(height: 20),
                ],

                // Libellé adapté selon le type de compte
                pw.Text(role == 'Parent' ? "Code d'Activation :" : "ID Professionnel :", style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                pw.Text(code, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),

                pw.Spacer(),

                pw.Center(
                  child: pw.Text(
                    "Veuillez conserver précieusement ce document. Ne le partagez pas.",
                    style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Fiche_Acces_TifliCare_${email.split('@')[0]}',
    );
  }

 
  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) => Container(margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)), padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: const Color(0xFF007BFF)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]), const SizedBox(height: 24), child]));

  Widget _buildAnimatedSwitch({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) => ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle), trailing: Switch(value: value, onChanged: onChanged, activeColor: Colors.red));

  @override
  void dispose() {
    _mainScrollController.dispose();
    _emailParentController.dispose(); _nomMereController.dispose(); _prenomMereController.dispose(); _dobMereController.dispose(); _ssMereController.dispose(); _nomPereController.dispose(); _prenomPereController.dispose(); _dobPereController.dispose(); _ssPereController.dispose(); _persoHistoryController.dispose(); _famHistoryController.dispose(); _nomProController.dispose(); _prenomProController.dispose(); _telProController.dispose(); _emailProController.dispose();
    super.dispose();
  }
}
