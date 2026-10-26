import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class VaccinAdminPage extends StatefulWidget {
  final String babyId;
  final String userRole;
  final DateTime dateNaissance; // pour calcul du retard

  const VaccinAdminPage({
    super.key,
    required this.babyId,
    required this.userRole,
    required this.dateNaissance,
  });

  @override
  State<VaccinAdminPage> createState() => _VaccinAdminPageState();
}

class _VaccinAdminPageState extends State<VaccinAdminPage> {
  final Color primaryBlue = const Color(0xFF4CB8C4);
  final Color darkBlue = const Color(0xFF3E5151);
  final Color softGreen = const Color(0xFF66BB6A);
  final Color alertRed = const Color(0xFFE57373);

  int get ageEnMois {
    return DateTime.now().difference(widget.dateNaissance).inDays ~/ 30;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text("Calendrier Vaccinal PEV", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance.collection('protocoles_vaccinaux').orderBy('ordre').snapshots(),
        builder: (context, protoSnap) {
          if (!protoSnap.hasData) return const Center(child: CircularProgressIndicator());


          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('babies').doc(widget.babyId).collection('vaccins').snapshots(),
            builder: (context, babySnap) {
              if (!babySnap.hasData) return const Center(child: CircularProgressIndicator());

              final administered = {for (var doc in babySnap.data!.docs) doc.id: doc.data() as Map<String, dynamic>};

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: protoSnap.data!.docs.length,
                itemBuilder: (context, index) {
                  var proto = protoSnap.data!.docs[index].data() as Map<String, dynamic>;
                  bool isDone = administered.containsKey(proto['id']);
                  bool isLate = !isDone && (ageEnMois > (proto['age_mois'] as int));

                  return _buildVaccinCard(proto, isDone, isLate, isDone ? administered[proto['id']] : null);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVaccinCard(Map<String, dynamic> proto, bool isDone, bool isLate, Map<String, dynamic>? data) {
    Color statusColor = isDone ? softGreen : (isLate ? alertRed : primaryBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: isLate || isDone ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(isDone ? Icons.check : (isLate ? Icons.priority_high : Icons.calendar_today), color: statusColor, size: 20),
        ),
        title: Text(proto['nom'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Âge requis : ${proto['age_label']}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (isDone) ...[
              const SizedBox(height: 4),
              Text("Fait le ${data?['date']} | Lot: ${data?['lot']}", style: TextStyle(color: softGreen, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
            if (isLate) ...[
              const SizedBox(height: 4),
              const Text("RETARD : À VACCINER D'URGENCE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ],
        ),
        trailing: !isDone && widget.userRole == "Vaccinateur"
            ? ElevatedButton(
          onPressed: () => _showAdministerModal(proto),
          style: ElevatedButton.styleFrom(backgroundColor: statusColor, elevation: 0, shape: const StadiumBorder()),
          child: const Text("Valider", style: TextStyle(color: Colors.white, fontSize: 12)),
        )
            : (isDone ? Icon(Icons.verified, color: softGreen) : null),
      ),
    );
  }

  void _showAdministerModal(Map<String, dynamic> proto) {
    final lotController = TextEditingController();
    final siteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enregistrer l'acte", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlue)),
            Text(proto['nom'], style: TextStyle(color: primaryBlue)),
            const SizedBox(height: 20),
            TextField(controller: lotController, decoration: const InputDecoration(labelText: "N° de Lot", prefixIcon: Icon(Icons.qr_code))),
            const SizedBox(height: 15),
            TextField(controller: siteController, decoration: const InputDecoration(labelText: "Site d'injection (Ex: Cuisse Gauche)", prefixIcon: Icon(Icons.location_on))),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  if (lotController.text.isEmpty) return;

                  // Récupérer le nom du soignant
                  String uid = FirebaseAuth.instance.currentUser!.uid;
                  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                  String nomSoignant = userDoc.exists ? "Dr. ${userDoc['nom']}" : "Soignant";

                  await FirebaseFirestore.instance
                      .collection('babies')
                      .doc(widget.babyId)
                      .collection('vaccins')
                      .doc(proto['id'])
                      .set({
                    'id': proto['id'],
                    'nom': proto['nom'],
                    'date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    'lot': lotController.text,
                    'site': siteController.text,
                    'admin_par': nomSoignant,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                },
                child: const Text("Confirmer l'injection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}