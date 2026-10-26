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
  final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? 'service_h0e9omx';
  final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? 'template_ks197eu';
  final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? 'bF-jo6U5WiKY8CSgW';

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

  Future<void> _handleCreation() async {
    if (!_validateForm()) return;

    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator())
      );

      final String email = selectedRole == 'Parent' ? _emailParentController.text.trim() : _emailProController.text.trim();
      final String password = _generatePassword();
      final String currentAdminId = _auth.currentUser?.uid ?? 'SYSTEM_ADMIN';

      String activationCode = '';
      String proID = '';

      UserCredential userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);


      Map<String, dynamic> data = {
        'uid': userCred.user!.uid,
        'email': email,
        'role': selectedRole,
        'tempPassword': password,
        'status': 'actif',
        'createdByAdminId': currentAdminId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (selectedRole == 'Parent') {
        activationCode = _generateActivationCode();
        data.addAll({
          'activationCode': activationCode,
          'isActivated': false,
          'mere': {
            'nom': _nomMereController.text.trim(),
            'prenom': _prenomMereController.text.trim(),
            'dob': _dobMereController.text.isNotEmpty ? DateTime.parse(_dobMereController.text) : null,
            'ss': int.tryParse(_ssMereController.text.trim()) ?? 0,
            'gs': gsMere,
            'rh': rhMere,
            'agglutinines': agglutinines,
          },
          'pere': {
            'nom': _nomPereController.text.trim(),
            'prenom': _prenomPereController.text.trim(),
            'dob': _dobPereController.text.isNotEmpty ? DateTime.parse(_dobPereController.text) : null,
            'ss': int.tryParse(_ssPereController.text.trim()) ?? 0,
          },
          'risques': {'consanguin': consanguin, 'radiations': radiations, 'medicaments': medicaments, 'tabac': tabac},
          'antecedents': {'personnels': _persoHistoryController.text.trim(), 'familiaux': _famHistoryController.text.trim()}
        });
      } else {
        proID = _generateProID();
        data.addAll({
          'nom': _nomProController.text.trim(),
          'prenom': _prenomProController.text.trim(),
          'telephone': _telProController.text.trim().replaceAll(' ', ''),
          'proID': proID,
        });
      }

      await _firestore.collection('users').doc(userCred.user!.uid).set(data);

      _sendEmailAutomatique(
          email,
          password,
          selectedRole == 'Parent' ? activationCode : proID
      ).catchError((e) => debugPrint("Erreur email silencieuse: $e"));

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _showSuccess(
              email,
              password,
              selectedRole == 'Parent' ? activationCode : proID,
              selectedRole
          );
        }
      });

    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: ${e.toString()}"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _resetFields() {
    setState(() {
      _emailParentController.clear();
      _nomMereController.clear();
      _prenomMereController.clear();
      _dobMereController.clear();
      _ssMereController.clear();
      _nomPereController.clear();
      _prenomPereController.clear();
      _dobPereController.clear();
      _ssPereController.clear();
      _persoHistoryController.clear();
      _famHistoryController.clear();
      _nomProController.clear();
      _prenomProController.clear();
      _telProController.clear();
      _emailProController.clear();

      gsMere = null; rhMere = null; gsPere = null; rhPere = null;
      agglutinines = false; consanguin = false; radiations = false; medicaments = false; tabac = false;
      _consentementRGPD = false;
      _errors.clear();
    });
  }

  void _showSuccess(String email, String pass, String code, String role) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 50),
              const SizedBox(height: 12),
              const Text("Compte créé avec succès", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _buildCredentialCard("👤 Rôle", role, dialogContext),
              const SizedBox(height: 8),
              _buildCredentialCard("📧 E-mail", email, dialogContext),
              const SizedBox(height: 8),
              if (role != 'Parent') ...[
                _buildCredentialCard("🔑 Mot de passe", pass, dialogContext),
                const SizedBox(height: 8),
              ],
              _buildCredentialCard(role == 'Parent' ? "🎫 Code d'Activation" : "🆔 ID Professionnel", code, dialogContext),

              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () => _imprimerFicheAcces(email, pass, code, role),
                  icon: const Icon(Icons.print, size: 10),
                  label: const Text("IMPRIMER LA FICHE ACCÈS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _resetFields();
                    _mainScrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                  },
                  child: const Text("Fermer et continuer")
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialCard(String label, String value, BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ])),
          IconButton(onPressed: () => Clipboard.setData(ClipboardData(text: value)), icon: const Icon(Icons.copy, size: 18, color: Colors.blue)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: _buildMainContent(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    switch (_currentNavIndex) {
      case 1:
        return _buildUsersListSection();
      case 2:
        return _buildDeletionRequestsSection();
      case 0:
      default:
        return SingleChildScrollView(
          controller: _mainScrollController,
          padding: EdgeInsets.all(isMobile ? 24.0 : 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Créer un compte utilisateur", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              const Text("Réservé à l'administrateur", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              _buildSectionCard(
                icon: Icons.person_outline,
                title: "Rôle de l'utilisateur",
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: _inputDecoration(),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() { selectedRole = val!; _errors.clear(); }),
                ),
              ),
              if (selectedRole == 'Parent') ...[
                _buildSectionCard(
                  icon: Icons.security,
                  title: "Protection des données",
                  child: CheckboxListTile(
                    title: const Text(
                      "Je confirme que les parents ont donné leur consentement pour le traitement informatisé des données de santé de l'enfant conformément au secret médical.",
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _consentementRGPD,
                    onChanged: (val) => setState(() => _consentementRGPD = val!),
                    activeColor: const Color(0xFF007BFF),
                  ),
                ),
                _buildSectionCard(icon: Icons.favorite_border, title: "Informations de la mère", child: _buildParentForm("Mère")),
                _buildSectionCard(icon: Icons.shield_outlined, title: "Informations du père", child: _buildParentForm("Père")),
                _buildSectionCard(icon: Icons.warning_amber_rounded, title: "Exposition aux risques", child: _buildRisksSection()),
                _buildSectionCard(icon: Icons.history, title: "Antécédents médicaux", child: _buildMedicalHistory()),
                _buildSectionCard(icon: Icons.email_outlined, title: "Compte parent", child: _buildParentAccount()),
              ] else ...[
                _buildSectionCard(icon: Icons.badge_outlined, title: "Informations personnelles", child: _buildProfessionalForm()),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text("Créer le compte et envoyer l'email"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007BFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _handleCreation,
                ),
              ),
            ],
          ),
        );
    }
  }


  Widget _buildUsersListSection() {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
          title: const Text("Utilisateurs enregistrés", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vos enregistrements", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Liste complète de tous les comptes enregistrés sur la plateforme.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(Icons.people_outline, "Aucun utilisateur actif trouvé.");
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var uData = doc.data() as Map<String, dynamic>;

                      String role = uData['role'] ?? 'Parent';
                      bool isParent = role == 'Parent';
                      String email = uData['email'] ?? 'Sans email';
                      String password = uData['tempPassword'] ?? '';
                      String uniqueCode = isParent ? (uData['activationCode'] ?? '') : (uData['proID'] ?? '');
                      String telephone = uData['telephone'] ?? uData['phone'] ?? 'N/A';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: (isParent ? Colors.pink : Colors.blue).withOpacity(0.1),
                            child: Icon(isParent ? Icons.family_restroom : Icons.badge, color: isParent ? Colors.pink : Colors.blue),
                          ),
                          title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Rôle : $role", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              if (isParent) ...[
                                Text("👩 Mère : ${uData['mere']?['nom'] ?? ''} ${uData['mere']?['prenom'] ?? ''}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                Text("👨 Père : ${uData['pere']?['nom'] ?? ''} ${uData['pere']?['prenom'] ?? ''}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                              ] else ...[
                                Text("👤 Nom : ${uData['nom'] ?? ''} ${uData['prenom'] ?? ''}", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                Text("📞 Tél : $telephone", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ],
                          ),

                          trailing: IconButton(
                            icon: const Icon(Icons.print, color: Color(0xFF007BFF)),
                            tooltip: "Imprimer la fiche d'accès",
                            onPressed: () => _imprimerFicheAcces(email, password, uniqueCode, role),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionRequestsSection() {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
          title: const Text("Demandes de résiliation", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          backgroundColor: Colors.white,
          elevation: 0
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Requêtes de suppression de compte", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Validation nécessaire. Conforme à la conservation clinique obligatoire (Soft Delete).", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users')
                    .where('status', isEqualTo: 'en_attente_suppression')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(Icons.check_circle_outline, "Aucune demande de résiliation en cours.");
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var uData = doc.data() as Map<String, dynamic>;
                      bool isParent = uData['role'] == 'Parent';

                      String nomUser = uData['nom'] ?? '';
                      String prenomUser = uData['prenom'] ?? '';

                      if (nomUser.isEmpty && isParent) {
                        if (uData['mere'] != null && uData['mere']['nom'] != null) {
                          nomUser = uData['mere']['nom'];
                          prenomUser = uData['mere']['prenom'] ?? '';
                        } else if (uData['pere'] != null && uData['pere']['nom'] != null) {
                          nomUser = uData['pere']['nom'];
                          prenomUser = uData['pere']['prenom'] ?? '';
                        }
                      }

                      String formatIdentite = (nomUser.isNotEmpty || prenomUser.isNotEmpty)
                          ? "${nomUser.toUpperCase()} $prenomUser"
                          : "Utilisateur Anonyme";

                      String telephone = uData['telephone'] ?? uData['phone'] ?? 'N/A';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Colors.redAccent, width: 0.5)
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFFEBEE),
                              child: Icon(Icons.warning_amber_rounded, color: Colors.red)
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatIdentite, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3436))),
                              const SizedBox(height: 2),
                              Text(uData['email'] ?? 'Sans email', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Rôle : ${uData['role']} • Statut : En attente d'approbation", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),

                                // Si ce n'est pas un parent (donc un Professionnel), on affiche aussi son numéro de téléphone
                                if (!isParent) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("Tél Pro : $telephone", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            icon: const Icon(Icons.no_accounts_outlined, size: 16),
                            label: const Text("Valider la désactivation"),
                            onPressed: () => _confirmSoftDeleteDialog(doc.id, uData),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _confirmSoftDeleteDialog(String uid, Map<String, dynamic> uData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text("Confirmer le Soft-Delete")]),
        content: const Text(
            "Cette action va révoquer définitivement l'authentification et vider les données personnelles identifiables (Email, Téléphone). L'historique clinique et les dossiers de suivi bébé resteront archivés anonymement conformément à la loi."
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _firestore.collection('users').doc(uid).update({
                'status': 'supprime',
                'email': 'ANONYMISED_${DateTime.now().millisecondsSinceEpoch}@tiflicare.com',
                'telephone': FieldValue.delete(),
                'tempPassword': FieldValue.delete(),
                'activationCode': FieldValue.delete(),
                'deletedAt': FieldValue.serverTimestamp(),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le compte a été purgé et désactivé avec succès."), backgroundColor: Colors.black));
              }
            },
            child: const Text("Désactiver définitivement"),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildParentForm(String type) {
    bool isMere = type == "Mère";
    return Column(children: [
      Row(children: [
        Expanded(child: _buildModernInput("Nom", "Nom", controller: isMere ? _nomMereController : _nomPereController, errorKey: isMere ? 'nomMere' : 'nomPere')),
        const SizedBox(width: 20),
        Expanded(child: _buildModernInput("Prénom", "Prénom", controller: isMere ? _prenomMereController : _prenomPereController, errorKey: isMere ? 'prenomMere' : 'prenomPere')),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _buildModernDateInput("Date de naissance", "aaaa-mm-jj", isMere ? _dobMereController : _dobPereController, errorKey: isMere ? 'dobMere' : 'dobPere')),
        const SizedBox(width: 20),
        Expanded(child: _buildModernInput("N° Sécurité sociale", "123...", controller: isMere ? _ssMereController : _ssPereController)),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _buildModernDropdown("Groupe sanguin", ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], (v) => setState(() => isMere ? gsMere = v : gsPere = v), errorKey: isMere ? 'gsMere' : null)),
        const SizedBox(width: 20),
        Expanded(child: _buildModernDropdown("Facteur Rh", ["Positif (+)", "Négatif (-)"], (v) => setState(() => isMere ? rhMere = v : rhPere = v), errorKey: isMere ? 'rhMere' : null)),
      ]),
      if (isMere) _buildAnimatedSwitch(title: "Agglutinines irrégulières", subtitle: "Présence", value: agglutinines, onChanged: (v) => setState(() => agglutinines = v)),
    ]);
  }

  Widget _buildProfessionalForm() => Column(children: [
    Row(children: [
      Expanded(child: _buildModernInput("Nom", "", controller: _nomProController, errorKey: 'nomPro')),
      const SizedBox(width: 20),
      Expanded(child: _buildModernInput("Prénom", "", controller: _prenomProController, errorKey: 'prenomPro')),
    ]),
    const SizedBox(height: 20),
    _buildModernInput("Téléphone", "+213...", controller: _telProController, errorKey: 'telPro'),
    const SizedBox(height: 20),
    _buildModernInput("Email professionnel", "nom@tiflicare.com", controller: _emailProController, errorKey: 'emailPro'),
  ]);

  Widget _buildParentAccount() => _buildModernInput("Adresse email du parent", "parent@exemple.com", controller: _emailParentController, errorKey: 'emailParent');

  Widget _buildRisksSection() => Column(children: [
    _buildAnimatedSwitch(title: "Mariage consanguin", subtitle: "Lien parenté", value: consanguin, onChanged: (v) => setState(() => consanguin = v)),
    _buildAnimatedSwitch(title: "Exposition aux radiations", subtitle: "Radios/Scanners", value: radiations, onChanged: (v) => setState(() => radiations = v)),
    _buildAnimatedSwitch(title: "Exposition Médicaments", subtitle: "Prise grossesse", value: medicaments, onChanged: (v) => setState(() => medicaments = v)),
    _buildAnimatedSwitch(title: "Exposition Tabac", subtitle: "Actif/Passif", value: tabac, onChanged: (v) => setState(() => tabac = v)),
  ]);

  Widget _buildMedicalHistory() => Column(children: [
    _buildModernInput("Antécédents personnels", "Détails...", lines: 3, controller: _persoHistoryController),
    const SizedBox(height: 20),
    _buildModernInput("Antécédents familiaux", "Héréditaires...", lines: 3, controller: _famHistoryController),
  ]);

  Widget _buildModernInput(String label, String hint, {int lines = 1, TextEditingController? controller, String? errorKey}) {
    List<TextInputFormatter>? formatters;
    if (label.toLowerCase().contains("nom") || label.toLowerCase().contains("prénom")) {
      formatters = [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Zàâçéèêëîïôûùüÿñæœ ]'))];
    }
    if (label.toLowerCase().contains("téléphone") || label.toLowerCase().contains("sécurité")) {
      formatters = [FilteringTextInputFormatter.digitsOnly];
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      TextField(
        controller: controller, maxLines: lines, inputFormatters: formatters,
        decoration: _inputDecoration(_errors[errorKey]).copyWith(hintText: hint),
        onChanged: (v) { if (errorKey != null) setState(() => _errors.remove(errorKey)); },
      ),
    ]);
  }

  Widget _buildModernDateInput(String label, String hint, TextEditingController controller, {String? errorKey}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      TextField(
        controller: controller, readOnly: true, onTap: () => _selectDate(context, controller),
        decoration: _inputDecoration(_errors[errorKey]).copyWith(hintText: hint, suffixIcon: const Icon(Icons.date_range, color: Color(0xFF007BFF))),
      ),
    ]);
  }

  Widget _buildModernDropdown(String label, List<String> items, Function(String?) onChanged, {String? errorKey}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        decoration: _inputDecoration(_errors[errorKey]),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: (val) { onChanged(val); if (errorKey != null) setState(() => _errors.remove(errorKey)); },
      ),
    ]);
  }

  InputDecoration _inputDecoration([String? errorText]) => InputDecoration(
    filled: true, fillColor: Colors.grey[50], errorText: errorText,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF007BFF), width: 2)),
  );


  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSidebarExpanded ? 260 : 85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [darkBlue, secondaryBlue],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.baby_changing_station,
                      size: 50,
                      color: Colors.white
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          _sidebarItem(Icons.person_add, "Créer un compte", 0),
          _sidebarItem(Icons.supervised_user_circle, "Liste Utilisateurs", 1),
          _sidebarItem(Icons.no_accounts, "Demandes Suppression", 2, iconColor: Colors.redAccent),

          const Spacer(),
          const Divider(indent: 5, endIndent: 5),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                }
              },
              leading: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
              title: isSidebarExpanded ? const Text("Déconnexion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              hoverColor: Colors.redAccent.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, int index, {Color? iconColor}) {
    bool isSelected = _currentNavIndex == index;
    return ListTile(
      onTap: () => setState(() => _currentNavIndex = index),
      leading: Icon(icon, color: isSelected ? Colors.white : (iconColor ?? Colors.white70)),
      title: isSidebarExpanded ? Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)) : null,
      tileColor: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
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