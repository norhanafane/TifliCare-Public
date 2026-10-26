import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HospitalisationPage extends StatelessWidget {
  final String babyId;
  const HospitalisationPage({super.key, required this.babyId});


  final Color primaryBlue = const Color(0xFF4CB8C4);
  final Color darkBlue = const Color(0xFF3E5151);
  final Color hospitalOrange = const Color(0xFFFB8C00);

  void _showAddModal(BuildContext context) {
    final hopitalController = TextEditingController();
    final entreeController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    final sortieController = TextEditingController();
    final motifController = TextEditingController();
    final diagnosticController = TextEditingController();
    final traitementController = TextEditingController();

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
              Text("Nouvelle Hospitalisation", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue)),
              const SizedBox(height: 20),

              _buildModernField(hopitalController, "Établissement Hospitalier", Icons.apartment_rounded, "Ex: CHU Oran, Clinique El Nour"),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildDateField(context, entreeController, "Date d'entrée")),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDateField(context, sortieController, "Date de sortie")),
                ],
              ),
              const SizedBox(height: 15),

              _buildModernField(motifController, "Motif d'admission", Icons.help_outline, "Ex: Fièvre persistante, Chirurgie"),
              const SizedBox(height: 15),

              _buildModernField(diagnosticController, "Diagnostic final", Icons.assignment_turned_in_outlined, "Conclusion médicale"),
              const SizedBox(height: 15),

              _buildModernField(traitementController, "Résumé du traitement", Icons.medication_outlined, "Médicaments, interventions...", maxLines: 2),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hospitalOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if(hopitalController.text.isEmpty || motifController.text.isEmpty) return;

                    try {
                      // TRAÇABILITÉ
                      String uid = FirebaseAuth.instance.currentUser!.uid;
                      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                      String medecinNom = userDoc.exists ? "Dr. ${userDoc['nom']} ${userDoc['prenom'] ?? ''}" : "Médecin Externe";

                      await FirebaseFirestore.instance.collection('babies').doc(babyId).collection('hospitalisations').add({
                        'hopital': hopitalController.text,
                        'entree': entreeController.text,
                        'sortie': sortieController.text.isEmpty ? "En cours" : sortieController.text,
                        'motif': motifController.text,
                        'diagnostic': diagnosticController.text,
                        'traitement': traitementController.text,
                        'enregistre_par': medecinNom,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                    } catch (e) {
                      print("Erreur: $e");
                    }
                  },
                  child: const Text("Enregistrer l'hospitalisation", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
        title: Text("Dossier Hospitalier", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _showAddModal(context),
            icon: Icon(Icons.add_business_rounded, color: hospitalOrange, size: 30),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('babies').doc(babyId).collection('hospitalisations').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildHospitalCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hospitalOrange.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.apartment_rounded, color: hospitalOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(data['hopital'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text("${data['entree']} ➜ ${data['sortie']}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hospitalOrange)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRowMedical("Motif d'admission", data['motif'], Icons.priority_high_rounded),
                _infoRowMedical("Diagnostic", data['diagnostic'], Icons.fact_check_outlined),
                _infoRowMedical("Traitement suivi", data['traitement'], Icons.healing_outlined),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Validé au dossier par :", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    Text(data['enregistre_par'] ?? "Médecin", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowMedical(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(text: "$label : ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  TextSpan(text: value.isEmpty ? "Non renseigné" : value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(TextEditingController ctrl, String label, IconData icon, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: hospitalOrange),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.calendar_today_outlined, color: hospitalOrange, size: 18),
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
          Icon(Icons.local_hospital_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text("Aucun historique d'hospitalisation", style: TextStyle(color: Colors.grey[400], fontSize: 15)),
        ],
      ),
    );
  }
}