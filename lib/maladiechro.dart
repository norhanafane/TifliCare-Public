import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MaladieChroniquePage extends StatelessWidget {
  final String babyId;
  final Map<String, dynamic> doctorData;
  const MaladieChroniquePage({super.key, required this.babyId, required this.doctorData});


  final Color primaryBlue = const Color(0xFF4CB8C4);
  final Color darkBlue = const Color(0xFF3E5151);
  final Color accentIndigo = const Color(0xFF5C6BC0);

  void _showAddModal(BuildContext context) {
    final nomController = TextEditingController();
    final dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    final traitementController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              Text("Suivi Maladie Chronique", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue)),
              const SizedBox(height: 20),

              _buildModernField(nomController, "Nom de la pathologie", Icons.biotech_outlined, "Ex: Asthme, Diabète type 1"),
              const SizedBox(height: 15),

              _buildDateField(context, dateController),
              const SizedBox(height: 15),

              _buildModernField(traitementController, "Plan thérapeutique", Icons.medication_liquid_outlined, "Ex: Ventoline 100µg en cas de crise"),
              const SizedBox(height: 15),

              _buildModernField(notesController, "Notes & Observations", Icons.event_note_outlined, "Précisez ici les symptômes ou antécédents...", maxLines: 3),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if(nomController.text.isEmpty) return;

                    // TRAÇABILITÉ
                    String docNom = doctorData['nom'] ?? "Inconnu";
                    String docPrenom = doctorData['prenom'] ?? "";

                    await FirebaseFirestore.instance.collection('babies').doc(babyId).collection('maladies_chroniques').add({
                      'nom': nomController.text,
                      'date': dateController.text,
                      'medecin': "Dr. $docNom $docPrenom",
                      'traitement': traitementController.text,
                      'notes': notesController.text,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Enregistrer au dossier", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Maladies Chroniques", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _showAddModal(context),
            icon: Icon(Icons.add_circle, color: primaryBlue, size: 32),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('babies').doc(babyId).collection('maladies_chroniques').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildMaladieCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaladieCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.monitor_heart_outlined, color: primaryBlue, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['nom'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3436))),
                      Text("Diagnostiqué le ${data['date']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            _labelValueRow(Icons.healing_outlined, "Traitement actuel", data['traitement']),
            const SizedBox(height: 12),
            _labelValueRow(Icons.notes_outlined, "Observations", data['notes']),

            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Validé par :", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: accentIndigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(data['medecin'], style: TextStyle(color: accentIndigo, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelValueRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(value.isEmpty ? "Aucune donnée" : value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildModernField(TextEditingController ctrl, String label, IconData icon, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
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

  Widget _buildDateField(BuildContext context, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Date de diagnostic",
        prefixIcon: Icon(Icons.calendar_month_outlined, color: primaryBlue),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text("Aucune maladie chronique enregistrée", style: TextStyle(color: Colors.grey[400], fontSize: 15)),
        ],
      ),
    );
  }
}