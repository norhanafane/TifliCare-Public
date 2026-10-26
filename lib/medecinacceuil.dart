import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'profilbebe.dart';
import 'login.dart';
import 'vaccinP.dart';
import 'hospi.dart';
import 'allergie.dart';
import 'maladiechro.dart';
import 'visiteP.dart';
import 'historiqueParent.dart';
import 'package:intl/intl.dart';

class PediatreHome extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  const PediatreHome({super.key, required this.doctorData});

  @override
  State<PediatreHome> createState() => _PediatreHomeState();
}

class _PediatreHomeState extends State<PediatreHome> {
  bool isSidebarExpanded = true;
  String? selectedBabyId;
  Map<String, dynamic>? selectedBabyData;
  final TextEditingController _searchController = TextEditingController();

  final Color primaryBlue = const Color(0xFF4CB8C4);
  final Color secondaryBlue = const Color(0xFF2196F3);
  final Color darkBlue = const Color(0xFF1A237E);
  final Color bgGrey = const Color(0xFFF4F7FA);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _navigateTo(Widget screen) {
    if (selectedBabyId == null) {
      _showSnackBar("Veuillez d'abord sélectionner un bébé");
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }


  Future<void> _requestDoctorAccountDeletion() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Droit à l'effacement (RGPD)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          "Souhaitez-vous demander la suppression définitive de votre compte professionnel ?\n\n"
              "Vos accès seront immédiatement suspendus. L'administrateur système procédera à la vérification et à la purge sécurisée de vos données d'identification conformément au protocole RGPD.",
          style: TextStyle(color: Colors.black87),
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'status': 'en_attente_suppression'});

        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _showSnackBar("Demande transmise à l'administrateur. Déconnexion... ");

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _showSnackBar("Erreur lors de la procédure : $e");
        }
      }
    }
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 400,
        child: MobileScanner(
          onDetect: (capture) {
            final barcode = capture.barcodes.first;
            if (barcode.rawValue != null) {
              Navigator.pop(context);
              _searchByQR(barcode.rawValue!);
            }
          },
        ),
      ),
    );
  }

  Future<void> _searchByQR(String babyId) async {
    var doc = await FirebaseFirestore.instance.collection('babies').doc(babyId).get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        selectedBabyId = doc.id;
        selectedBabyData = data;
        _searchController.text = "";
      });

      _showSnackBar("Bébé sélectionné : ${data['nom']}");
    } else {
      _showSnackBar("Code invalide");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tableau de bord",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                        ),
                        const SizedBox(height: 20),
                        _buildSearchBox(),
                        if (_searchController.text.isNotEmpty) _buildSearchResults(),
                        const SizedBox(height: 30),
                        if (selectedBabyId != null)
                          _buildSelectedBabyCard()
                        else
                          _buildEmptyState(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    bool isVaccinateur = widget.doctorData['role'] == "Vaccinateur" ;

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
          const SizedBox(height: 20),
          Image.asset('assets/logo.png', height: isSidebarExpanded ? 60 : 40),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _sidebarItem(Icons.dashboard_rounded, "Accueil", () {
                    setState(() {
                      selectedBabyId = null;
                      selectedBabyData = null;
                      _searchController.clear();
                    });
                  }),
                  _sidebarItem(Icons.child_care_rounded, "Profil Bébé", () {
                    _navigateTo(BabyProfilePage(
                        babyId: selectedBabyId ?? '',
                        babyData: selectedBabyData ?? {}
                    ));
                  }),
                  if (!isVaccinateur) ...[
                    _sidebarItem(Icons.history_rounded, "Visites", () {
                      _navigateTo(PediatricVisitAdmin(babyId: selectedBabyId ?? '', doctorData: widget.doctorData));
                    }),
                  ],
                  _sidebarItem(Icons.vaccines_rounded, "Vaccinations", () {
                    if (selectedBabyId == null || selectedBabyData == null) {
                      _showSnackBar("Veuillez d'abord sélectionner un bébé");
                      return;
                    }

                    String dateStr = selectedBabyData!['dateNaissance'] ?? '';
                    DateTime dateParsed;

                    try {
                      dateParsed = DateFormat("dd/MM/yyyy").parse(dateStr);
                    } catch (e) {
                      dateParsed = DateTime.now();
                      print("Erreur format date: $e");
                    }

                    Navigator.push(context, MaterialPageRoute(builder: (context) => VaccinAdminPage(
                      babyId: selectedBabyId!,
                      userRole: widget.doctorData['role'] ?? 'Médecin',
                      dateNaissance: dateParsed,
                    )));
                  }),
                  _sidebarItem(Icons.warning_rounded, "Allergies", () {
                    _navigateTo(AllergiePage(
                        babyId: selectedBabyId ?? '',
                        userRole: widget.doctorData['role'] ?? "Inconnu"
                    ));
                  }),
                  if (!isVaccinateur) ...[
                    _sidebarItem(Icons.medical_services_rounded, "Maladies Chroniques", () {
                      _navigateTo(MaladieChroniquePage(
                          babyId: selectedBabyId ?? '',
                          doctorData: widget.doctorData
                      ));
                    }),
                    _sidebarItem(Icons.local_hospital_rounded, "Hospitalisations", () {
                      _navigateTo(HospitalisationPage(babyId: selectedBabyId ?? ''));
                    }),
                    _sidebarItem(Icons.history, "Hist. Alim & Croissance", () {
                      _navigateTo(HistoriqueParentPage(babyId: selectedBabyId ?? ''));
                    }),
                  ],
                ],
              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                            (route) => false
                    );
                  }
                },
                leading: const Icon(Icons.power_settings_new_rounded, color: Colors.red, size: 20),
                title: isSidebarExpanded
                    ? const Text("Déconnexion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white, size: 24),
      title: isSidebarExpanded ? Text(title, style: const TextStyle(color: Colors.white)) : null,
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(isSidebarExpanded ? Icons.menu_open : Icons.menu, color: darkBlue),
            onPressed: () => setState(() => isSidebarExpanded = !isSidebarExpanded),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Dr. ${widget.doctorData['nom'] ?? 'Médecin'}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.doctorData['role'] ?? 'Pédiatre', style: TextStyle(fontSize: 12, color: primaryBlue)),
            ],
          ),
          const SizedBox(width: 15),


          PopupMenuButton<String>(
            tooltip: "Options du compte",
            onSelected: (value) {
              if (value == 'delete_account') {
                _requestDoctorAccountDeletion();
              }
            },
            offset: const Offset(0, 50),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFF0F2F5),
              child: Icon(Icons.person, color: Color(0xFFFF2600)),
            ),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  "Connecté en tant que Dr. ${widget.doctorData['nom'] ?? ''}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete_account',
                child: Row(
                  children: const [
                    Icon(Icons.no_accounts_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text("Supprimer mon compte", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Rechercher un bébé...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
            onPressed: _openScanner,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('babies').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        var results = snapshot.data!.docs.where((doc) {
          String nom = doc['nom'].toString().toLowerCase();
          return nom.contains(_searchController.text.toLowerCase()) || doc.id.contains(_searchController.text);
        }).toList();

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]
          ),
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, i) {
              var data = results[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text("${data['nom']} ${data['prenom'] ?? ''}"),
                subtitle: Text("ID: ${results[i].id}"),
                onTap: () {
                  setState(() {
                    selectedBabyId = results[i].id;
                    selectedBabyData = data;
                    _searchController.clear();
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedBabyCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryBlue, const Color(0xFF3A7BD5)]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 35, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 40, color: Colors.white)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${selectedBabyData?['nom']} ${selectedBabyData?['prenom'] ?? ''}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("ID: $selectedBabyId", style: const TextStyle(color: Colors.white70)),
                Text("Né le: ${selectedBabyData?['dateNaissance']}", style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text(
            "Utilisez la barre de recherche pour sélectionner un bébé\nou scanner son code QR",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}