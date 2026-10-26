import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AllergiePage extends StatelessWidget {
  final String babyId;
  final String userRole;
  const AllergiePage({super.key, required this.babyId, required this.userRole});


  final Color primaryBlue = const Color(0xFF4CB8C4);
  final Color darkBlue = const Color(0xFF3E5151);

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case "Sévère": return const Color(0xFFE57373);
      case "Modérée": return const Color(0xFFFFB74D);
      case "Légère": return const Color(0xFF81C784);
      default: return Colors.blueGrey;
    }
  }

  void _showAddModal(BuildContext context) {
    String? selectedType;
    String selectedSeverity = "Légère";
    final allergeneController = TextEditingController();
    final reactionController = TextEditingController();
    final dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text("Nouvelle Allergie", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue)),
                const SizedBox(height: 20),

                _buildModernField(allergeneController, "Allergène", Icons.bug_report_outlined, "Ex: Pénicilline, Arachide"),
                const SizedBox(height: 15),

                _buildDropdownField(
                  "Type d'allergie",
                  Icons.category_outlined,
                  ["Alimentaire", "Médicament", "Environnemental"],
                      (val) => setModalState(() => selectedType = val),
                ),
                const SizedBox(height: 15),

                _buildModernField(reactionController, "Type de réaction", Icons.medical_services_outlined, "Ex: Éruptions cutanées, Œdème"),
                const SizedBox(height: 15),

                Text("Niveau de Sévérité", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["Légère", "Modérée", "Sévère"].map((s) {
                    bool isSelected = selectedSeverity == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: isSelected,
                      selectedColor: _getSeverityColor(s).withOpacity(0.2),
                      labelStyle: TextStyle(color: isSelected ? _getSeverityColor(s) : Colors.grey, fontWeight: FontWeight.bold),
                      onSelected: (val) => setModalState(() => selectedSeverity = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),

                _buildDateField(context, dateController),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () async {
                      if(allergeneController.text.isEmpty || selectedType == null) return;

                      try {
                        // TRAÇABILITÉ
                        String uid = FirebaseAuth.instance.currentUser!.uid;
                        DocumentSnapshot userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get();

                        String medecinNom = "Inconnu";

                        if (userDoc.exists) {

                          String nom = userDoc.get('nom') ?? "";
                          String prenom = userDoc.get('prenom') ?? "";


                          medecinNom = "Dr. $nom $prenom".trim();


                          if (medecinNom == "Dr.") {
                            medecinNom = "Dr. Inconnu";
                          }
                        }
                        await FirebaseFirestore.instance
                            .collection('babies')
                            .doc(babyId)
                            .collection('allergies')
                            .add({
                          'allergene': allergeneController.text,
                          'type': selectedType,
                          'reaction': reactionController.text,
                          'severite': selectedSeverity,
                          'date': dateController.text,
                          'detecte_par': medecinNom,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        Navigator.pop(context);
                      } catch (e) {
                        print("Erreur lors de l'enregistrement : $e");

                      }
                    },
                    child: const Text(
                        "Enregistrer le diagnostic",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canEdit = userRole != "Vaccinateur";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Allergies & Intolérances", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
        actions: [
          // LE BOUTON S'AFFICHE UNIQUEMENT SI CE N'EST PAS UN VACCINATEUR
          if (canEdit)
            IconButton(
              onPressed: () => _showAddModal(context),
              icon: Icon(Icons.add_circle, color: primaryBlue, size: 30),
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('babies').doc(babyId).collection('allergies').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              Color sevColor = _getSeverityColor(data['severite']);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Container(width: 8, color: sevColor),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(data['allergene'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    _buildBadge(data['severite'], sevColor),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _infoIconText(Icons.category_outlined, data['type']),
                                _infoIconText(Icons.warning_amber_rounded, "Réaction : ${data['reaction']}"),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _infoIconText(Icons.calendar_today_outlined, "Le ${data['date']}"),
                                    Text("Par : ${data['detecte_par'] ?? 'Inconnu'}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }



  Widget _buildModernField(TextEditingController ctrl, String label, IconData icon, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField(String label, IconData icon, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField(BuildContext context, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Date de détection",
        prefixIcon: Icon(Icons.event, color: primaryBlue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      onTap: () async {
        DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
        if (picked != null) ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
      },
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoIconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucune allergie signalée", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}