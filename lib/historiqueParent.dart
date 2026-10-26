import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoriqueParentPage extends StatelessWidget {
  final String babyId;
  const HistoriqueParentPage({super.key, required this.babyId});

  // Couleurs
  final Color primaryBlue = const Color(0xFF0091EA);
  final Color darkBlueGrey = const Color(0xFF2D3436);
  final Color background = const Color(0xFFF4F7F9);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text("Suivi des Parents",
              style: TextStyle(color: darkBlueGrey, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryBlue,
            tabs: const [
              Tab(icon: Icon(Icons.straighten), text: "Croissance"),
              Tab(icon: Icon(Icons.restaurant), text: "Alimentation"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMesuresList(),
            _buildRepasList(),
          ],
        ),
      ),
    );
  }

  // SECTION CROISSANCE

  Widget _buildMesuresList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('babies')
          .doc(babyId)
          .collection('measures')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState("Aucune mesure enregistrée");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            DateTime date = (data['date'] as Timestamp).toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        _buildBadge("IMC: ${data['imc'] ?? '--'}", Colors.orange),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _mesureItemPro(Icons.monitor_weight_outlined, "${data['poids']} kg", "Poids",
                            _getEvolution(docs, index, 'poids', 'kg')),
                        _mesureItemPro(Icons.height, "${data['taille']} cm", "Taille",
                            _getEvolution(docs, index, 'taille', 'cm')),
                        _mesureItemPro(Icons.face_outlined, "${data['pc']} cm", "P.C",
                            _getEvolution(docs, index, 'pc', 'cm')),
                      ],
                    ),
                  ),

                  if (data['notes'] != null && data['notes'] != "")
                    _buildNoteBox(data['notes']),
                ],
              ),
            );
          },
        );
      },
    );
  }


  // SECTION ALIMENTATION

  Widget _buildRepasList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('babies')
          .doc(babyId)
          .collection('repas')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState("Aucun repas enregistré");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            DateTime time = (data['timestamp'] as Timestamp).toDate();

            // Logique de distinction Lait / Solide
            bool isLiquid = data['type'].toString().toLowerCase().contains('biberon') ||
                data['type'].toString().toLowerCase().contains('lait');

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border(left: BorderSide(color: isLiquid ? Colors.blue : Colors.green, width: 6)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLiquid ? Colors.blue.shade50 : Colors.green.shade50,
                  child: Icon(isLiquid ? Icons.opacity : Icons.restaurant,
                      color: isLiquid ? Colors.blue : Colors.green, size: 20),
                ),
                title: Text(data['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Quantité : ${data['quantite']}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('HH:mm').format(time),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Text(DateFormat('dd/MM').format(time), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  // Calcul de la différence entre deux dates
  String _getEvolution(List<QueryDocumentSnapshot> docs, int index, String field, String unit) {
    if (index + 1 >= docs.length) return "Initiale";
    try {
      double current = double.parse(docs[index][field].toString());
      double previous = double.parse(docs[index + 1][field].toString());
      double diff = current - previous;
      String sign = diff >= 0 ? "+" : "";
      return "$sign${diff.toStringAsFixed(2)} $unit";
    } catch (e) { return "--"; }
  }

  Widget _mesureItemPro(IconData icon, String val, String label, String evo) {
    bool isPositive = evo.contains('+');
    return Column(
      children: [
        Icon(icon, color: primaryBlue, size: 22),
        const SizedBox(height: 5),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: isPositive ? Colors.green.withOpacity(0.1) : Colors.blueGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5)
          ),
          child: Text(evo, style: TextStyle(
              color: isPositive ? Colors.green.shade700 : Colors.blueGrey,
              fontSize: 10, fontWeight: FontWeight.bold
          )),
        ),
      ],
    );
  }

  Widget _buildNoteBox(String note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.2))
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, size: 20, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(child: Text(note, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}