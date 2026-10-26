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
