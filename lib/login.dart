import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medecinacceuil.dart';
import 'admininterface.dart';
import 'parentAcceuil.dart';
import 'sagefemmeNeo.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';

// --- FONCTION D'ENVOI DE L'EMAIL 2FA
Future<void> _sendEmailAutomatique(String email, String sujet, String code) async {
  final serviceId = dotenv.env['EMAILJS_SERVICE_ID']  ;
  final templateId = dotenv.env['EMAILJS_2FA_TEMPLATE_ID']  ;
  final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ;
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
          'user_password': sujet,
          'activation_code': code,
        },
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ Email 2FA envoyé avec succès à $email !");
    } else {
      debugPrint("❌ Échec de l'envoi EmailJS : ${response.body}");
    }
  } catch (e) {
    debugPrint("🚨 Erreur réseau lors de l'envoi de l'email : $e");
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late bool isProfessional;
  String? selectedRole;
  bool obscurePassword = true;
  bool isLoading = false;

  final TextEditingController identifiantController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final List<String> roles = [
    'Sage-femme',
    'Néonatologue',
    'Médecin',
    'Vaccinateur',
    'Administrateur'
  ];

  // =========================================================================
  // FONCTION DE RÉINITIALISATION DU MOT DE PASSE (UNIQUEMENT PARENT)
  // =========================================================================
  Future<void> handleForgotPassword() async {
    // Si c'est un professionnel, on interdit l'action
    if (isProfessional) {
      _showError("La réinitialisation autonome est réservée aux parents. Veuillez contacter votre administrateur.");
      return;
    }

    String inputID = identifiantController.text.trim();

    if (inputID.isEmpty) {
      _showError("Veuillez saisir votre Code d'activation dans le champ ci-dessus pour recevoir le lien.");
      return;
    }

    setState(() => isLoading = true);

    try {
      String fieldSearch = 'activationCode';
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where(fieldSearch, isEqualTo: inputID)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw "Code d'activation introuvable.";
      }

      String email = userQuery.docs.first.data()['email'];

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Un e-mail de réinitialisation sécurisé a été envoyé à : $email"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  Future<bool> _showForceChangePasswordDialog(User user) async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isUpdating = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    bool result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: Colors.redAccent, size: 28),
                  SizedBox(width: 10),
                  Text("Sécurité Obligatoire", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Il s'agit de votre première connexion. Pour protéger vos données de santé, veuillez définir un nouveau mot de passe personnalisé.",
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: "Nouveau mot de passe",
                      labelStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: "Confirmer le mot de passe",
                      labelStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: isUpdating ? null : () async {
                    String newPass = newPasswordController.text.trim();
                    String confirmPass = confirmPasswordController.text.trim();

                    if (newPass.isEmpty || confirmPass.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Veuillez remplir les deux champs"), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    if (newPass.length < 6) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Le mot de passe doit contenir au moins 6 caractères"), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    if (newPass != confirmPass) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Les mots de passe ne correspondent pas"), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    setDialogState(() => isUpdating = true);

                    try {
                      await user.updatePassword(newPass);

                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'tempPassword': FieldValue.delete(),
                      });

                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      setDialogState(() => isUpdating = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text("Erreur de mise à jour : ${e.toString()}"), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: isUpdating
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Enregistrer et continuer", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;

    return result;
  }


  Future<void> handleLogin() async {
    String inputID = identifiantController.text.trim();
    String password = passwordController.text.trim();

    if (inputID.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    if (isProfessional && selectedRole == null) {
      _showError("Veuillez choisir votre rôle");
      return;
    }

    setState(() => isLoading = true);

    try {
      String? emailToSignIn;
      Map<String, dynamic>? userData;
      String? userUid;

      if (selectedRole == "Administrateur") {
        emailToSignIn = "$inputID@gmail.com";
      } else {
        String fieldSearch = isProfessional ? 'proID' : 'activationCode';
        var userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where(fieldSearch, isEqualTo: inputID)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          throw isProfessional ? "ID Professionnel invalide" : "Code d'activation invalide";
        }

        var userDoc = userQuery.docs.first;
        userData = userDoc.data();
        userUid = userDoc.id;
        emailToSignIn = userData['email'];

        if (userData.containsKey('status')) {
          String status = userData['status'];
          if (status == 'supprime') {
            throw "Ce compte a été désactivé ou supprimé par l'administration.";
          } else if (status == 'suspendu') {
            throw "Ce compte est temporairement suspendu. Contactez votre administrateur.";
          }
        }
      }

      UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToSignIn!,
        password: password,
      );

      if (selectedRole == "Administrateur") {
        _redirectProfessional("Administrateur", adminInputId: inputID);
        return;
      }

      if (userData == null && userUid != null) {
        DocumentSnapshot freshDoc = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
        userData = freshDoc.data() as Map<String, dynamic>?;
      }

      String roleDB = userData?['role'] ?? '';

      if (isProfessional) {
        if (roleDB != selectedRole) {
          await FirebaseAuth.instance.signOut();
          throw "Ce compte n'a pas le rôle $selectedRole";
        }

        if (!mounted) return;
        setState(() => isLoading = false);

        bool verification2FASuccess = await _showTwoFactorDialog(emailToSignIn);

        if (verification2FASuccess) {
          _redirectProfessional(roleDB, data: userData);
        } else {
          await FirebaseAuth.instance.signOut();
          _showError("Échec de la vérification à deux facteurs.");
        }

      } else {
        if (userData != null && userData.containsKey('tempPassword')) {
          if (!mounted) return;
          setState(() => isLoading = false);

          bool passwordChanged = await _showForceChangePasswordDialog(userCred.user!);

          if (!passwordChanged) {
            await FirebaseAuth.instance.signOut();
            _showError("Vous devez modifier votre mot de passe pour accéder à votre espace.");
            return;
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentAccueil()),
        );
      }
    } on FirebaseAuthException catch (_) {
      _showError("Identifiants ou mot de passe incorrect");
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  Future<bool> _showTwoFactorDialog(String email) async {
    final TextEditingController otpController = TextEditingController();
    bool? isVerified = false;
    bool isVerifyingOtp = false;

    final String codeGenere = (100000 + Random().nextInt(900000)).toString();

    await _sendEmailAutomatique(email, "Vérification de sécurité", codeGenere);

    if (!mounted) return false;

    isVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.blue),
                  SizedBox(width: 10),
                  Text("Double Authentification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Un code de vérification temporaire a été envoyé à :", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 5),
                  Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 8),
                      counterText: "",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text(
                    "Passer (Démo)",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: isVerifyingOtp ? null : () async {
                    setDialogState(() => isVerifyingOtp = true);
                    await Future.delayed(const Duration(milliseconds: 500));

                    if (otpController.text.trim() == codeGenere) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      setDialogState(() => isVerifyingOtp = false);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Code de validation incorrect"), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: isVerifyingOtp
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Vérifier"),
                ),
              ],
            );
          },
        );
      },
    );

    return isVerified ?? false;
  }
  void _redirectProfessional(String role, {Map<String, dynamic>? data, String? adminInputId}) {
    if (role == "Administrateur") {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => AdminDashboard(adminId: adminInputId ?? "ADMIN_GENERAL")
          )
      );
    } else if (role == "Médecin" || role == "Vaccinateur") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PediatreHome(doctorData: data ?? {})),
      );
    } else if (role == "Sage-femme" || role == "Néonatologue") {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SaggeNeo(doctorData: data ?? {}))
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      isProfessional = true;
    } else {
      isProfessional = false;
      selectedRole = "Parent";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      body: isMobile
          ? _buildForm(context, isMobile)
          : Row(
        children: [
          Expanded(child: _buildLeftPanel()),
          Expanded(child: _buildForm(context, isMobile)),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/bebe.jpg', fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.35)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("Carnet de Santé Digital", textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text("Votre interface professionnelle pour un suivi pédiatrique précis et une prise en charge coordonnée.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool isMobile) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', height: 40),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("TifliCare", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Carnet Digital", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Connexion", textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(child: _buildTypeButton("Professionnel", true)),
                      Expanded(child: _buildTypeButton("Parent", false)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                _buildTextField(isProfessional ? "ID Professionnel (PRO-XXXX)" : "Code d'activation (BABY-XXXX)", identifiantController),
                const SizedBox(height: 15),
                _buildPasswordField(),


                if (!isProfessional)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading ? null : handleForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                if (isProfessional) ...[
                  const SizedBox(height: 5),
                  _buildDropdownField(),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isLoading ? null : handleLogin,
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Se connecter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String text, bool value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isProfessional = value;
          selectedRole = value ? null : "Parent";
          identifiantController.clear();
          passwordController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isProfessional == value ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(text,
            style: TextStyle(color: isProfessional == value ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: obscurePassword,
      decoration: InputDecoration(
        labelText: "Mot de passe",
        labelStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: IconButton(
          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: selectedRole == "Parent" ? null : selectedRole,
      hint: const Text("Choisir votre rôle"),
      items: roles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) => setState(() => selectedRole = val),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
