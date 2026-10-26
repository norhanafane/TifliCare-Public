import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'login.dart';

class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  final Color primaryBlue = const Color(0xFF4CB8C4);
  final Color darkBlue = const Color(0xFF3E5151);
  final Color bgGrey = const Color(0xFFF8FAFB);

  bool notifVaccin = true;
  double delaiRappel = 7;
  bool rappel24h = true;


  Future<void> _requestAccountDeletion() async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Droit à l'effacement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          "Souhaitez-vous demander la suppression définitive de vos données personnelles ?\n\n"
              "Conformément à la réglementation, vos accès seront suspendus immédiatement. L'administrateur validera la purge de vos données identifiables tout en préservant le dossier clinique requis par la loi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirmer la demande"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        if (user != null) {

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .update({'status': 'en_attente_suppression'});


          await FirebaseAuth.instance.signOut();

          if (mounted) {

            Navigator.of(context, rootNavigator: true).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Demande enregistrée. Déconnexion réussie."),
                backgroundColor: Colors.orangeAccent,
              ),
            );


            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de la demande : $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Text("Mon Profil Santé", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: darkBlue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildEnhancedProfileHeader(),
            const SizedBox(height: 30),
            _buildSectionHeader("Accès Familial", Icons.family_restroom_rounded),
            _buildFamilyModernCard(),
            const SizedBox(height: 30),
            _buildSectionHeader("Configuration des Alertes", Icons.notifications_active_outlined),
            _buildSmartNotificationCard(),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: _requestAccountDeletion,
              icon: const Icon(Icons.delete_forever, size: 20),
              label: const Text("SUPPRIMER MON COMPTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                side: const BorderSide(color: Colors.redAccent, width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                minimumSize: const Size(double.infinity, 55),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryBlue, primaryBlue.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: bgGrey,
                  child: Icon(Icons.person_rounded, size: 50, color: primaryBlue),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.verified, color: Colors.blue.shade700, size: 20),
              )
            ],
          ),
          const SizedBox(height: 15),
          const Text("Parent Référent", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.email ?? "Email non disponible", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(
              "ID FAMILLE : ${user?.uid.substring(0, 8).toUpperCase()}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyModernCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.share_arrival_time_rounded, color: Colors.amber),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Inviter un membre", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Partagez le suivi avec le conjoint", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Share.share(
                  "👨‍👩‍👧‍👦 Rejoins le suivi médical de notre bébé sur TifliCare !\n\n"
                      "1️⃣ Télécharge l'application\n"
                      "2️⃣ Crée ton compte\n"
                      "3️⃣ Entre mon code famille : ${user?.uid.substring(0, 8).toUpperCase()}\n\n"
                      "Lien : https://tiflicare.app/download"
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: bgGrey,
              foregroundColor: darkBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              minimumSize: const Size(double.infinity, 55),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: primaryBlue),
                const SizedBox(width: 10),
                const Text("Envoyer le code d'accès sécurisé", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          _buildToggle(
            "Alertes Vaccins & Visites",
            "Rappels automatiques pour le calendrier",
            Icons.health_and_safety_outlined,
            notifVaccin,
                (v) => setState(() => notifVaccin = v),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Anticipation du rappel", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("${delaiRappel.round()} jours avant", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: delaiRappel,
                  min: 1, max: 14,
                  activeColor: primaryBlue,
                  inactiveColor: primaryBlue.withOpacity(0.1),
                  onChanged: notifVaccin ? (v) => setState(() => delaiRappel = v) : null,
                ),
              ],
            ),
          ),
          _buildToggle(
            "Rappel de sécurité 24h",
            "Dernière alerte la veille du RDV",
            Icons.notification_important_outlined,
            rappel24h,
            notifVaccin ? (v) => setState(() => rappel24h = v) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryBlue),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue)),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String sub, IconData icon, bool val, Function(bool)? onChanged) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: primaryBlue, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      value: val,
      activeColor: primaryBlue,
      onChanged: onChanged,
    );
  }
}