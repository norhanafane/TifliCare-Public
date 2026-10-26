import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notificationservice.dart';

class MedicalVisitsPage extends StatefulWidget {
  final String babyId;
  final Map<String, dynamic> babyData;

  const MedicalVisitsPage({super.key, required this.babyId, required this.babyData});

  @override
  State<MedicalVisitsPage> createState() => _MedicalVisitsPageState();
}

class _MedicalVisitsPageState extends State<MedicalVisitsPage> {
  bool rappel7j = true;
  bool rappel24h = true;
  int heurePrefere = 9;
  bool _notificationsProgrammees = false;

  final List<Map<String, dynamic>> calendrierVisites = [
    {"id": "sys_8_jours", "jours": 8, "titre": "Examen de naissance", "age": "0-8 jours"},
    {"id": "sys_1_mois", "jours": 30, "titre": "Visite du 1er mois", "age": "1 mois"},
    {"id": "sys_2_mois", "jours": 60, "titre": "Suivi des 2 mois", "age": "2 mois"},
    {"id": "sys_4_mois", "jours": 120, "titre": "Suivi des 4 mois", "age": "4 mois"},
    {"id": "sys_9_mois", "jours": 274, "titre": "Bilan des 9 mois", "age": "9 mois"},
    {"id": "sys_12_mois", "jours": 365, "titre": "Suivi des 12 mois", "age": "12 mois"},
    {"id": "sys_18_mois", "jours": 548, "titre": "Bilan des 18 mois", "age": "18 mois"},
  ];

  DateTime _calculateDate(int days) {
    dynamic raw = widget.babyData['dateNaissance'];
    DateTime birthDate = raw is Timestamp ? raw.toDate() : DateTime.tryParse(raw.toString()) ?? DateTime.now();
    return birthDate.add(Duration(days: days));
  }


  void _programmerNotificationsSiNecessaire(Map doneVisits) {
    if (_notificationsProgrammees) return;
    _notificationsProgrammees = true;

    for (var v in calendrierVisites) {

      final String uniqueIdStr = "visite_${v['id']}";
      final int idBase = uniqueIdStr.hashCode.abs();

      if (!doneVisits.containsKey(v['id'])) {
        NotificationService.programmerRappels(
          idBase: idBase,
          titre: "Visite : ${v['titre']}",
          nomBebe: widget.babyData['nom'] ?? "votre bébé",
          datePrevue: _calculateDate(v['jours']),
          activePremierRappel: rappel7j,
          joursAvant: 7,
          active7Jours: rappel7j,
          active24h: rappel24h,
          heureRappel: heurePrefere,
        );
      }
    }
  }

  void _ouvrirReglages() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Paramètres des rappels", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SwitchListTile(
                title: const Text("1 semaine avant"),
                value: rappel7j,
                onChanged: (v) {
                  setModalState(() => rappel7j = v);
                  setState(() => rappel7j = v);
                },
              ),
              SwitchListTile(
                title: const Text("24h avant"),
                value: rappel24h,
                onChanged: (v) {
                  setModalState(() => rappel24h = v);
                  setState(() => rappel24h = v);
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Suivi Médical", style: TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: Colors.lightBlue),
            onPressed: _ouvrirReglages,
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('babies').doc(widget.babyId).collection('visites').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final doneVisits = {for (var doc in snapshot.data!.docs) doc['id']: doc.data() as Map<String, dynamic>};

          _programmerNotificationsSiNecessaire(doneVisits);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text("Visites de ${widget.babyData['nom']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...calendrierVisites.asMap().entries.map((entry) {
                final v = entry.value;
                final bool isDone = doneVisits.containsKey(v['id']);
                final targetDate = _calculateDate(v['jours']);
                return _buildVisitTimelineItem(v, isDone, doneVisits[v['id']], targetDate, entry.key == calendrierVisites.length - 1);
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVisitTimelineItem(Map<String, dynamic> v, bool isDone, Map? data, DateTime targetDate, bool isLast) {
    final diff = targetDate.difference(DateTime.now()).inDays;
    bool isSoon = !isDone && diff <= 7 && diff >= 0;
    Color color = isDone ? Colors.teal : (isSoon ? Colors.redAccent : Colors.blueGrey);

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
            if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
          ]),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20),
                border: isSoon ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5) : null,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(v['titre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (isSoon) const Icon(Icons.notification_important, color: Colors.redAccent, size: 18),
                ]),
                const SizedBox(height: 5),
                Text(
                  isDone ? "Effectuée le ${data?['date']}" : "À faire le : ${DateFormat('dd/MM/yyyy').format(targetDate)}",
                  style: TextStyle(color: isSoon ? Colors.redAccent : Colors.grey.shade600, fontSize: 13, fontWeight: isSoon ? FontWeight.bold : FontWeight.normal),
                ),
                if (isDone) ...[
                  const Divider(height: 20),
                  Text(data?['conclusion'] ?? "Examen clinique normal.", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.teal)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}