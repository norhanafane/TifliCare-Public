import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'croissance.dart';
import 'alimentation.dart';
import 'articles.dart';
import 'vaccin.dart';
import 'visite.dart';
import 'parametrepage.dart';
import 'login.dart';
import 'chatscreen.dart';

class ParentAccueil extends StatefulWidget {
  const ParentAccueil({super.key});

  @override
  State<ParentAccueil> createState() => _ParentAccueilState();
}

class _ParentAccueilState extends State<ParentAccueil> {
  String? selectedBabyId;
  final Color medicalBlue = const Color(0xFF4CB8C4);

  Widget _statItem(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 5),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }

  // Calcul d'âge
  String _calculateAge(dynamic date) {
    if (date == null) return "Date inconnue";
    try {
      DateTime birth;
      if (date is Timestamp) {
        birth = date.toDate();
      } else if (date is String) {
        birth = DateTime.tryParse(date) ?? DateTime.now();
      } else {
        return "Format inconnu";
      }

      DateTime now = DateTime.now();
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

      if (years > 0) return "$years an${years > 1 ? 's' : ''}";
      if (months > 0) return "$months mois${days > 0 ? ' et $days jours' : ''}";
      return "$days jours";
    } catch (e) {
      return "Date invalide";
    }
  }


  void _showQrCodeModal(String babyId, String babyFirstName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 15,
            left: 25,
            right: 25,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)
                ),
              ),
              const SizedBox(height: 20),

              const Icon(Icons.qr_code_scanner_rounded, size: 36, color: Color(0xFF318785)),
              const SizedBox(height: 10),

              Text(
                "QR Code",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Text(
                "Le médecin peut scanner ce code pour ouvrir instantanément le dossier de $babyFirstName.",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),


              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: QrImageView(
                  data: babyId,
                  version: QrVersions.auto,
                  size: 170.0,
                  gapless: false,
                ),
              ),
              const SizedBox(height: 15),


              SelectableText(
                "ID unique : $babyId",
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Courier'),
              ),
              const SizedBox(height: 25),


              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fermer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPage();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("TifliCare", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
                Text("Carnet de santé digital", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParametresPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('babies')
            .where('parentUid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var babies = snapshot.data!.docs;


          if (selectedBabyId != null) {
            var babyDoc = babies.firstWhereOrNull((b) => b.id == selectedBabyId);
            if (babyDoc != null) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [

                          _professionalProfileCard(babyDoc.id, babyDoc.data() as Map<String, dynamic>),
                          const SizedBox(height: 25),
                          _menuList(babyDoc.id, babyDoc.data() as Map<String, dynamic>, babies),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          }


          return ListView(
            padding: const EdgeInsets.all(20),
            children: babies.map((baby) {
              var data = baby.data() as Map<String, dynamic>;
              return _babyCard(
                name: data['prenom'] ?? "Inconnu",
                date: data['dateNaissance'] ?? "",
                sexe: data['sexe'] ?? "",
                age: _calculateAge(data['dateNaissance']),
                onTap: () => setState(() => selectedBabyId = baby.id),
              );
            }).toList(),
          );
        },
      ),
    );
  }


  Widget _professionalProfileCard(String babyId, Map<String, dynamic> data) {
    String babyName = data['prenom'] ?? data['nom'] ?? "Bébé";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF318785), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CB8C4).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.child_care, size: 40, color: Color(0xFF4CB8C4)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            babyName,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              _calculateAge(data['dateNaissance']),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),


                    IconButton(
                      onPressed: () => _showQrCodeModal(babyId, babyName),
                      icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 30),
                      tooltip: "Afficher le QR Code",
                    ),

                    IconButton(
                      onPressed: () => setState(() => selectedBabyId = null),
                      icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28),
                      tooltip: "Changer d'enfant",
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem("Poids", "${data['mensurations']?['poids'] ?? '--'} kg", Icons.monitor_weight_outlined),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _statItem("Taille", "${data['mensurations']?['taille'] ?? '--'} cm", Icons.height_rounded),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _statItem("Sexe", data['sexe'] ?? "--", Icons.person_outline_rounded),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _babyCard({required String name, required String date, required String sexe, required String age, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.child_care, size: 35, color: Colors.blue)),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 4),
          Text("$age • $sexe", style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Ouvrir le carnet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _menuList(String babyId, Map<String, dynamic> babyData, List allDocs) {
    return Column(
      children: [
        _menu("Croissance", "Courbes et mesures", Icons.trending_up,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => CroissancePage(babyId: babyId, babyData: babyData)))),
        _menu("Alimentation", "Suivi des repas", Icons.restaurant,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlimentationPage(babyId: babyId, babyData: babyData)))),
        _menu("Vaccins", "Calendrier vaccinal", Icons.vaccines,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => VaccinationPage(babyId: babyId, babyData: babyData)))),
        _menu("Visites", "Consultations médicales", Icons.medical_services,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalVisitsPage(babyId: babyId, babyData: babyData)))),
        _menu("Articles & Conseils", "Santé et éveil", Icons.library_books,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => EducationalArticlesScreen()))),
        // <-- AJOUT DE L'ASSISTANT IA DANS LE MENU -->
        _menu("Assistant IA TifliCare", "Conseils pédiatriques & OMS", Icons.smart_toy_rounded,
                () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(babyId: babyId, babyData: babyData) // <-- On transmet babyData ici
                )
            )),
      ],
    );
  }

  Widget _menu(String title, String sub, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.child_friendly_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 15),
          Text("Aucun bébé enregistré.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}