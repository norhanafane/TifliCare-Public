import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notificationservice.dart';

class VaccinationPage extends StatefulWidget {
  final String babyId;
  final Map<String, dynamic> babyData;

  const VaccinationPage({super.key, required this.babyId, required this.babyData});

  @override
  State<VaccinationPage> createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage> {

  bool rappel7j = true;
  bool rappel24h = true;
  int heurePrefere = 9;
  bool _notificationsProgrammees = false;


  DateTime _getDueDate(int monthsFromBirth) {
    try {
      dynamic raw = widget.babyData['dateNaissance'];
      DateTime birthDate = raw is Timestamp ? raw.toDate() : DateTime.tryParse(raw.toString()) ?? DateTime.now();
      return DateTime(birthDate.year, birthDate.month + monthsFromBirth, birthDate.day);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Calcul de l'âge actuel pour le statut "En retard"
  int get ageEnMois {
    try {
      dynamic raw = widget.babyData['dateNaissance'];
      DateTime birthDate = raw is Timestamp ? raw.toDate() : DateTime.tryParse(raw.toString()) ?? DateTime.now();
      return DateTime.now().difference(birthDate).inDays ~/ 30;
    } catch (e) { return 0; }
  }

  void _programmerNotificationsSiNecessaire(List<QueryDocumentSnapshot> protocoles, Map administered) {
    if (_notificationsProgrammees) return;
    _notificationsProgrammees = true;

    for (var doc in protocoles) {
      var proto = doc.data() as Map<String, dynamic>;
      final String idStr = proto['id'];

      if (!administered.containsKey(idStr)) {
        NotificationService.programmerRappels(
          idBase: idStr.hashCode.abs(),
          titre: proto['nom'],
          nomBebe: widget.babyData['prenom'] ?? widget.babyData['nom'] ?? "votre bébé",
          datePrevue: _getDueDate(proto['age_mois']),
          activePremierRappel: false,
          joursAvant: 7,
          active7Jours: rappel7j,
          active24h: rappel24h,
          heureRappel: heurePrefere,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Carnet de Vaccination", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: () {
                String prenomBebe = widget.babyData['prenom'] ?? widget.babyData['nom'] ?? "le bébé";

                // Appel 15 secondes
                NotificationService.testerExact15Sec(
                  titre: "Rappel Vaccination (Démo)",
                  corps: "C'est le moment de vacciner $prenomBebe !",
                  secondes: 15,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("🚀 Notif programmée pour $prenomBebe (15s)"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Color(0xFF6C63FF)),
            onPressed: _ouvrirReglagesNotifs,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance.collection('protocoles_vaccinaux').orderBy('ordre').snapshots(),
        builder: (context, protoSnap) {
          if (!protoSnap.hasData) return const Center(child: CircularProgressIndicator());

          final protocoles = protoSnap.data!.docs;

          return StreamBuilder<QuerySnapshot>(

            stream: FirebaseFirestore.instance.collection('babies').doc(widget.babyId).collection('vaccins').snapshots(),
            builder: (context, babySnap) {
              if (!babySnap.hasData) return const Center(child: CircularProgressIndicator());

              final administered = {for (var doc in babySnap.data!.docs) doc.id: doc.data() as Map<String, dynamic>};


              _programmerNotificationsSiNecessaire(protocoles, administered);


              int effectues = administered.length;
              int enRetard = protocoles.where((p) => !administered.containsKey(p['id']) && ageEnMois > (p['age_mois'] as int)).length;
              double progression = protocoles.isEmpty ? 0 : effectues / protocoles.length;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStatCards(effectues, protocoles.length - effectues, enRetard),
                  const SizedBox(height: 25),
                  _buildProgressionBar(progression),
                  const SizedBox(height: 30),
                  ...protocoles.map((doc) {
                    var proto = doc.data() as Map<String, dynamic>;
                    bool isDone = administered.containsKey(proto['id']);
                    bool isLate = !isDone && (ageEnMois > (proto['age_mois'] as int));

                    return _buildVaccinTimelineItem(
                      proto: proto,
                      isDone: isDone,
                      isLate: isLate,
                      adminData: isDone ? administered[proto['id']] : null,
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCards(int fait, int avenir, int retard) {
    return Row(
      children: [
        _card(fait.toString(), "Faits", Colors.teal, Icons.check_circle_outline),
        const SizedBox(width: 10),
        _card(avenir.toString(), "À venir", Colors.blue, Icons.calendar_month),
        const SizedBox(width: 10),
        _card(retard.toString(), "Retard", Colors.redAccent, Icons.warning_amber_rounded),
      ],
    );
  }

  Widget _card(String val, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)]),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildProgressionBar(double percent) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Progression", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text("${(percent * 100).toInt()}%", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: percent, backgroundColor: Colors.grey.shade100, color: Colors.teal, minHeight: 6),
      ]),
    );
  }

  Widget _buildVaccinTimelineItem({required Map<String, dynamic> proto, required bool isDone, required bool isLate, Map<String, dynamic>? adminData}) {
    Color statusColor = isDone ? Colors.teal : (isLate ? Colors.red : Colors.blueGrey);
    DateTime dueDate = _getDueDate(proto['age_mois']);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(proto['nom'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              _badge(isDone ? "EFFECTUÉ" : (isLate ? "EN RETARD" : "PRÉVU"), statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                isDone ? "Fait le ${adminData?['date']}" : "Prévu le ${DateFormat('dd MMMM yyyy').format(dueDate)}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (isDone) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            Text("💉 Par: ${adminData?['admin_par']} | Lot: ${adminData?['lot']}", style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _badge(String txt, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(txt, style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.bold)),
  );

  void _ouvrirReglagesNotifs() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Préférences de rappel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text("Rappel 7 jours avant"),
                value: rappel7j,
                onChanged: (v) { setModalState(() => rappel7j = v); setState(() => rappel7j = v); },
              ),
              SwitchListTile(
                title: const Text("Rappel 24h avant"),
                value: rappel24h,
                onChanged: (v) { setModalState(() => rappel24h = v); setState(() => rappel24h = v); },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), minimumSize: const Size(double.infinity, 50), shape: StadiumBorder()),
                onPressed: () { _notificationsProgrammees = false; Navigator.pop(context); },
                child: const Text("Mettre à jour les rappels", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}