import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SaggeNeo extends StatelessWidget {
  final Map<String, dynamic> doctorData;
  const SaggeNeo({super.key, required this.doctorData});

  @override
  Widget build(BuildContext context) {
    return MainDashboard(doctorData: doctorData);
  }
}

class MainDashboard extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  const MainDashboard({super.key, required this.doctorData});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  bool isSidebarExpanded = true;
  String? _selectedParentId;
  String? _selectedParentNames;

  final Color primaryBlue = const Color(0xFF4CB8C4);
  final Color secondaryBlue = const Color(0xFF2196F3);
  final Color darkBlue = const Color(0xFF1A237E);
  final Color bgGrey = const Color(0xFFF4F7FA);


  Future<void> _requestAccountDeletion() async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Demander la suppression", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          "Souhaitez-vous envoyer une demande de suppression de compte à l'administrateur ?\n\n"
              "Conformément à la réglementation médicale, vos accès seront immédiatement suspendus en attendant la validation et l'anonymisation de votre profil par l'administration.",
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
            child: const Text("Envoyer la demande"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
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

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Demande transmise. Vos accès sont suspendus jusqu'à validation."),
                  backgroundColor: Colors.orangeAccent
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
            SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Row(
        children: [
          AnimatedContainer(
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
                const SizedBox(height: 40),
                Image.asset('assets/logo.png', height: isSidebarExpanded ? 60 : 40),
                const SizedBox(height: 40),
                _sidebarItem(Icons.person_search_rounded, "Recherche Parent", 0),
                _sidebarItem(Icons.baby_changing_station_rounded, "Nouveau Dossier", 1),
                const Spacer(),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
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
                      leading: const Icon(Icons.power_settings_new_rounded, color: Colors.red, size: 24),
                      title: isSidebarExpanded
                          ? const Text("Déconnexion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: _selectedIndex == 0
                      ? TableDeBordPage(onParentSelected: (uid, names) {
                    setState(() {
                      _selectedParentId = uid;
                      _selectedParentNames = names;
                      _selectedIndex = 1;
                    });
                  })
                      : CreationProfilBebePage(
                    doctorData: widget.doctorData,
                    parentUid: _selectedParentId,
                    parentNames: _selectedParentNames,
                    onSuccess: () {
                      setState(() {
                        _selectedIndex = 0;
                        _selectedParentId = null;
                        _selectedParentNames = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      onTap: () => setState(() => _selectedIndex = index),
      leading: Icon(icon, color: isSelected ? primaryBlue : Colors.white70),
      title: isSidebarExpanded ? Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)) : null,
      tileColor: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
    );
  }


  Widget _buildTopHeader() {
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
              Text("Dr. ${widget.doctorData['nom'] ?? 'Praticien'}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.doctorData['role'] ?? 'Sage-femme', style: TextStyle(fontSize: 12, color: primaryBlue)),
            ],
          ),
          const SizedBox(width: 15),


          PopupMenuButton<String>(
            tooltip: "Options du compte",
            onSelected: (value) {
              if (value == 'delete_account') {
                _requestAccountDeletion();
              }
            },
            offset: const Offset(0, 50),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFF0F2F5),
              child: Icon(Icons.person, color: Color(0xFFFF0000)),
            ),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  "Connecté : Dr. ${widget.doctorData['nom'] ?? ''}",
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
                    Text(
                      "Supprimer mon compte",
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TableDeBordPage extends StatefulWidget {
  final Function(String, String) onParentSelected;
  const TableDeBordPage({super.key, required this.onParentSelected});

  @override
  State<TableDeBordPage> createState() => _TableDeBordPageState();
}

class _TableDeBordPageState extends State<TableDeBordPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Identification des Parents", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
          const Text("Liez le nouveau-né à un compte parent existant", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          _buildSearchBox(),
          const SizedBox(height: 30),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Parent').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var filteredDocs = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String searchLower = searchQuery.toLowerCase();
                String mNom = (data['mere']?['nom'] ?? "").toLowerCase();
                String pNom = (data['pere']?['nom'] ?? "").toLowerCase();
                return mNom.contains(searchLower) || pNom.contains(searchLower);
              }).toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  var data = filteredDocs[index].data() as Map<String, dynamic>;
                  String nomPere = data['pere']?['nom']?.toUpperCase() ?? 'N/A';
                  String displayNames = "Famille $nomPere";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                          backgroundColor: const Color(0xFF4CB8C4).withOpacity(0.1),
                          child: const Icon(Icons.people, color: Color(0xFF4CB8C4))
                      ),
                      title: Text(displayNames, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Mère: ${data['mere']?['nom'] ?? ''} ${data['mere']?['prenom'] ?? ''}"),
                          Text("Père: ${data['pere']?['nom'] ?? ''} ${data['pere']?['prenom'] ?? ''}"),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CB8C4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        onPressed: () => widget.onParentSelected(filteredDocs[index].id, displayNames),
                        child: const Text("Sélectionner", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: TextField(
        onChanged: (val) => setState(() => searchQuery = val),
        decoration: const InputDecoration(
          hintText: "Rechercher un parent (Nom)...",
          prefixIcon: Icon(Icons.search, color: Color(0xFF4CB8C4)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

class CreationProfilBebePage extends StatefulWidget {
  final String? parentUid;
  final String? parentNames;
  final Map<String, dynamic> doctorData;
  final VoidCallback onSuccess;
  const CreationProfilBebePage({super.key, this.parentUid, this.parentNames, required this.onSuccess, required this.doctorData});

  @override
  State<CreationProfilBebePage> createState() => _CreationProfilBebePageState();
}

class _CreationProfilBebePageState extends State<CreationProfilBebePage> {
  final _nomBebe = TextEditingController();
  final _prenomBebe = TextEditingController();
  final _dateNais = TextEditingController();
  final _lieuNais = TextEditingController();
  final _poids = TextEditingController();
  final _taille = TextEditingController();
  final _pc = TextEditingController();
  final _apgar1 = TextEditingController();
  final _apgar5 = TextEditingController();
  final _apgar10 = TextEditingController();
  final _raisonAlim = TextEditingController();

  String sexe = "Masculin";
  String typeAlimentation = "Allaitement maternel exclusif";

  Map<String, bool> examNeonat = {
    "Cri immédiat": false, "Aspiration": false, "Intubation": false, "Adrénaline": false,
    "Réanimation nécessaire": false, "Ventilation au masque": false, "Massage cardiaque": false,
  };
  Map<String, bool> examPhysique = {
    "Malformations visibles": false, "Yeux normaux": true, "Souffle cardiaque": false, "Splénomégalie": false,
    "Perméabilité anale": true, "Pieds et mains normaux": true, "Malformation anorectale": false,
    "Oreilles normales": true, "Hépatomégalie": false, "Organes génitaux normaux": true, "Hanches normales": true,
  };

  void _clearFields() {
    _nomBebe.clear();
    _prenomBebe.clear();
    _dateNais.clear();
    _lieuNais.clear();
    _poids.clear();
    _taille.clear();
    _pc.clear();
    _apgar1.clear();
    _apgar5.clear();
    _apgar10.clear();
    _raisonAlim.clear();

    setState(() {
      sexe = "Masculin";
      typeAlimentation = "Allaitement maternel exclusif";
      examNeonat.updateAll((key, value) => false);
      examPhysique.forEach((key, value) {
        if (key == "Yeux normaux" || key == "Perméabilité anale" ||
            key == "Pieds et mains normaux" || key == "Oreilles normales" ||
            key == "Organes génitaux normaux" || key == "Hanches normales") {
          examPhysique[key] = true;
        } else {
          examPhysique[key] = false;
        }
      });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateNais.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveBaby() async {
    if (widget.parentUid == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String creatorName = "Dr. ${widget.doctorData['nom'] ?? ''} ${widget.doctorData['prenom'] ?? ''}".trim();

      DocumentReference babyRef = await FirebaseFirestore.instance.collection('babies').add({
        'parentUid': widget.parentUid,
        'nom': _nomBebe.text,
        'prenom': _prenomBebe.text,
        'dateNaissance': _dateNais.text,
        'sexe': sexe,
        'lieuNaissance': _lieuNais.text,
        'mensurations': {
          'poids': _poids.text,
          'taille': _taille.text,
          'pc': _pc.text
        },
        'apgar': {
          '1min': _apgar1.text,
          '5min': _apgar5.text,
          '10min': _apgar10.text
        },
        'examenNeonat': examNeonat,
        'examenPhysique': examPhysique,
        'alimentation': {
          'type': typeAlimentation,
          'raisonNonExclusive': _raisonAlim.text
        },
        'creePar': creatorName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      _showShareOptions(babyRef.id, "${_prenomBebe.text} ${_nomBebe.text}");

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la création : $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showShareOptions(String babyId, String babyFullName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(25),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                const Text("Dossier créé avec succès !", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Text("Bébé : $babyFullName", style: const TextStyle(fontSize: 16, color: Colors.blueGrey), textAlign: TextAlign.center),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: QrImageView(
                    data: babyId,
                    version: QrVersions.auto,
                    size: 160.0,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText("ID : $babyId", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("Transmettre au parent :", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionBtn(
                      icon: Icons.send_rounded,
                      label: "Envoyer",
                      color: Colors.blue,
                      onTap: () => Share.share("Bienvenue sur TifliCare ! Code de suivi pour $babyFullName : $babyId"),
                    ),
                    _buildActionBtn(
                      icon: Icons.print_rounded,
                      label: "Imprimer",
                      color: Colors.orange,
                      onTap: () => _printBabyQR(babyId, babyFullName),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _clearFields();
                      widget.onSuccess();
                    },
                    child: const Text("TERMINER ET RETOURNER", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _printBabyQR(String id, String name) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text("TIFLICARE", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text("CARNET DE SANTE NUMERIQUE", style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text("Nouveau-ne : $name", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 15),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: id,
                  width: 130,
                  height: 130,
                ),
                pw.SizedBox(height: 15),
                pw.Text("Presentez ce code lors de vos consultations", style: const pw.TextStyle(fontSize: 7)),
                pw.Text("ID : $id", style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Fiche_TifliCare_$name',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parentUid == null) return const Center(child: Text("Sélectionnez d'abord un parent."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dossier Nouveau-né", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Chip(label: Text(widget.parentNames!), backgroundColor: const Color(0xFF4CB8C4).withOpacity(0.1), labelStyle: const TextStyle(color: Color(0xFF4CB8C4))),
            ],
          ),
          const SizedBox(height: 25),
          _buildCard("Informations de Base", Icons.info_outline, Column(children: [
            _buildField("Nom du bébé", _nomBebe),
            const SizedBox(height: 15),
            _buildField("Prénom du bébé", _prenomBebe),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(child: _buildField("Date de Naissance", _dateNais)),
            ),
            const SizedBox(height: 15),
            _buildField("Lieu de Naissance", _lieuNais),
            const SizedBox(height: 15),
            _buildDropdown("Sexe", ["Masculin", "Féminin"], (v) => setState(() => sexe = v!)),
          ])),
          _buildCard("Mensurations & APGAR", Icons.straighten, Column(children: [
            Row(children: [
              Expanded(child: _buildField("Poids (g)", _poids)),
              const SizedBox(width: 10),
              Expanded(child: _buildField("Taille (cm)", _taille)),
              const SizedBox(width: 10),
              Expanded(child: _buildField("PC (cm)", _pc))
            ]),
            const Divider(height: 40),
            const Text("Scores APGAR", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _buildField("1 min", _apgar1)),
              const SizedBox(width: 10),
              Expanded(child: _buildField("5 min", _apgar5)),
              const SizedBox(width: 10),
              Expanded(child: _buildField("10 min", _apgar10))
            ]),
          ])),
          _buildCard("Examen Néonatal", Icons.assignment_outlined, Wrap(spacing: 10, children: examNeonat.keys.map((k) => _buildCheck(k, examNeonat)).toList())),
          _buildCard("Examen Physique", Icons.favorite_border, Wrap(spacing: 10, children: examPhysique.keys.map((k) => _buildCheck(k, examPhysique)).toList())),
          _buildCard("Alimentation", Icons.restaurant, Column(children: [
            _buildDropdown("Type d'alimentation", ["Allaitement maternel exclusif", "Allaitement mixte", "Allaitement artificiel"], (v) => setState(() => typeAlimentation = v!)),
            if (typeAlimentation != "Allaitement maternel exclusif") ...[const SizedBox(height: 15), _buildField("Raison si non exclusif", _raisonAlim, lines: 2)],
          ])),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _saveBaby,
              child: const Text("CRÉER LE DOSSIER SANTÉ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: const Color(0xFF4CB8C4), size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {int lines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: items[0],
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildCheck(String label, Map<String, bool> map) {
    return SizedBox(
      width: 210,
      child: CheckboxListTile(
        title: Text(label, style: const TextStyle(fontSize: 12)),
        value: map[label],
        onChanged: (v) => setState(() => map[label] = v!),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}