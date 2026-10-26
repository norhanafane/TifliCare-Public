import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AlimentationPage extends StatefulWidget {
  final String babyId;
  final Map<String, dynamic> babyData;

  const AlimentationPage({super.key, required this.babyId, required this.babyData});

  @override
  State<AlimentationPage> createState() => _AlimentationPageState();
}

class _AlimentationPageState extends State<AlimentationPage> {

  // Calcul d'âge
  int _getAgeMonths() {
    try {
      DateTime birthDate;
      var rawDate = widget.babyData['dateNaissance'];
      if (rawDate is Timestamp) birthDate = rawDate.toDate();
      else birthDate = DateTime.parse(rawDate.toString().replaceAll('/', '-'));

      DateTime now = DateTime.now();
      int months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
      if (now.day < birthDate.day) months--;
      return months;
    } catch (e) {
      return 0;
    }
  }

  String _formatAgeText(int months) {
    if (months < 1) return "Nouveau-né";
    if (months < 24) return "$months mois";
    return "${months ~/ 12} ans ${months % 12} mois";
  }

  @override
  Widget build(BuildContext context) {
    int ageMonths = _getAgeMonths();
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(ageMonths),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNutritionDashboard(todayStr),
                  const SizedBox(height: 25),
                  _buildModernGuide(ageMonths),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Programme du jour", Icons.calendar_today_rounded),
                  const SizedBox(height: 15),
                  _buildDailyProgram(todayStr),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(int months) {
    return SliverAppBar(
      expandedHeight: 120, pinned: true, backgroundColor: Colors.white, elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Alimentation", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Âge : ${_formatAgeText(months)}", style: const TextStyle(color: Color(0xFF0091EA), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15, top: 10),
          child: IconButton.filled(
            onPressed: () => _showAddRepasPopup(months),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF0091EA), minimumSize: const Size(45, 45)),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        )
      ],
    );
  }

  Widget _buildNutritionDashboard(String date) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('babies').doc(widget.babyId).collection('repas')
          .where('date', isEqualTo: date).snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        double liquide = 0;
        double solide = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            var d = doc.data() as Map<String, dynamic>;
            double qty = double.tryParse(d['quantite'].toString().split(' ')[0]) ?? 0;
            String type = (d['type'] as String).toLowerCase();
            if (type.contains('lait') || type.contains('biberon')) liquide += qty;
            else solide += qty;
          }
        }
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0091EA), Color(0xFF00B0FF)]
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryCol("Repas", "$count"),
              _divider(),
              _summaryCol("Lait/Liquide", "${liquide.toInt()} ml"),
              _divider(),
              _summaryCol("Solide/Divers", "${solide.toInt()} g"),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.white24);

  Widget _summaryCol(String label, String val) {
    return Column(children: [
      Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildModernGuide(int months) {
    List<Map<String, dynamic>> tips = [
      {'icon': Icons.opacity, 'color': Colors.blue, 'title': 'Base Laitière',
        'desc': months < 6 ? 'Allaitement maternel exclusif recommandé (à la demande).' : 'Lait maternel ou 2ème âge (minimum 500ml/jour).'}
    ];

    if (months >= 4 && months < 6) {
      tips.add({'icon': Icons.info_outline, 'color': Colors.orange, 'title': 'Prémices', 'desc': 'Vous pouvez commencer à faire goûter quelques cuillères de légumes mixés.'});
    }
    if (months >= 6) {
      tips.add({'icon': Icons.soup_kitchen, 'color': Colors.green, 'title': 'Diversification', 'desc': 'Purées lisses de légumes (carotte, potiron) et compotes sans sucre ajouté.'});
      tips.add({'icon': Icons.egg_rounded, 'color': Colors.red, 'title': 'Protéines', 'desc': '10g (2 c.à.c) de viande ou poisson mixé, ou 1/4 d\'œuf dur.'});
    }
    if (months >= 10) {
      tips.add({'icon': Icons.restaurant, 'color': Colors.purple, 'title': 'Textures', 'desc': 'Passage aux petits morceaux fondants. Introduction du fromage et yaourt.'});
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Text("CONSEILS PERSONNALISÉS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue.shade900, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 15),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: tip['color'].withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Icon(tip['icon'], color: tip['color'], size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(tip['desc'], style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12, height: 1.4)),
                  ],
                ))
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDailyProgram(String dateIso) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('babies').doc(widget.babyId).collection('repas')
          .where('date', isEqualTo: dateIso).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }
        var docs = snapshot.data!.docs;
        docs.sort((a, b) => (a['heure'] as String).compareTo(b['heure'] as String));

        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            bool isLait = data['type'].toString().contains('Lait');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: isLait ? Colors.blue.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Icon(isLait ? Icons.opacity : Icons.restaurant, color: isLait ? Colors.blue : Colors.orange, size: 20),
                ),
                title: Text(data['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("${data['quantite']} ${data['notes'] != '' ? '• ${data['notes']}' : ''}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: Text(data['heure'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Icon(Icons.restaurant_menu_rounded, color: Colors.grey.shade300, size: 40),
        const SizedBox(height: 12),
        const Text("Aucun repas aujourd'hui", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _showAddRepasPopup(int months) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRepasForm(babyId: widget.babyId, months: months),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [Icon(icon, size: 18, color: Colors.blueGrey), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]);
  }
}

class _AddRepasForm extends StatefulWidget {
  final String babyId; final int months;
  const _AddRepasForm({required this.babyId, required this.months});
  @override State<_AddRepasForm> createState() => _AddRepasFormState();
}

class _AddRepasFormState extends State<_AddRepasForm> {
  String? selectedType;
  bool isCustomType = false;
  final customTypeCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  TimeOfDay selectedTime = TimeOfDay.now();
  String unit = "ml";

  // Listes de suggestions
  final Map<String, List<int>> suggestions = {
    "ml": [90, 120, 150, 180, 210, 240],
    "g": [30, 60, 100, 130, 150, 200],
    "min": [5, 10, 15, 20, 30],
  };

  @override
  void initState() {
    super.initState();
    selectedType = _getFoodList().first;
    _updateUnit(selectedType!);
  }

  void _updateUnit(String type) {
    setState(() {
      if (type.contains("Lait") || type.contains("Biberon")) {
        unit = "ml";
      } else if (type.contains("Allaitement")) {
        unit = "min";
      } else {
        unit = "g" ;
      }
    });
  }

  List<String> _getFoodList() {
    List<String> foods = ["Biberon Lait", "Allaitement"];
    if (widget.months >= 4) foods.addAll(["Purée", "Compote"]);
    if (widget.months >= 6) foods.addAll(["Laitage", "Protéines"]);
    return foods;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Text("Nouveau Repas", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 20),

            // --- TYPE D'ALIMENT ---
            const Text("TYPE D'ALIMENT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [
                ..._getFoodList().map((type) => _buildTypeChip(type)),
                _buildOtherChip(),
              ],
            ),

            if (isCustomType) _buildCustomTypeField(),

            const SizedBox(height: 25),
            // --- QUANTITÉ & HEURE ---
            const Text("UNITÉ ET MESURE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 10),

            // Sélecteur G / ML (Apparaît si ce n'est pas de l'allaitement)
            if (unit != "min")
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    _buildUnitToggle("g", "Grammes"),
                    const SizedBox(width: 10),
                    _buildUnitToggle("ml", "Millilitres"),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("QUANTITÉ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: InputDecoration(
                          suffixText: unit,
                          filled: true, fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("HEURE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      _buildTimeTile(),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // --- SUGGESTIONS RAPIDES (ML, G, MIN) ---
            if (suggestions.containsKey(unit))
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: suggestions[unit]!.map((val) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text("$val $unit"),
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0091EA)),
                      backgroundColor: const Color(0xFF0091EA).withOpacity(0.05),
                      side: BorderSide(color: const Color(0xFF0091EA).withOpacity(0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onPressed: () => setState(() => qtyCtrl.text = val.toString()),
                    ),
                  )).toList(),
                ),
              ),

            const SizedBox(height: 25),

            // --- NOTES ---
            const Text("NOTES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: "Remarque (ex: Tout fini !)",
                prefixIcon: const Icon(Icons.edit_note_rounded, size: 24),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 30),

            // --- BOUTON VALIDER ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0091EA),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Enregistrer le repas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUnitToggle(String value, String label) {
    bool isSelected = unit == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => unit = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0091EA) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTypeChip(String type) {
    bool isSel = selectedType == type && !isCustomType;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
          isCustomType = false;
          _updateUnit(type);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0091EA).withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? const Color(0xFF0091EA) : Colors.transparent, width: 1.5),
        ),
        child: Text(type, style: TextStyle(color: isSel ? const Color(0xFF0091EA) : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
      ),
    );
  }

  Widget _buildOtherChip() {
    return GestureDetector(
      onTap: () => setState(() { isCustomType = true; selectedType = null; unit = "g"; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCustomType ? const Color(0xFF0091EA).withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCustomType ? const Color(0xFF0091EA) : Colors.transparent, width: 1.5),
        ),
        child: Text("Autre +", style: TextStyle(color: isCustomType ? const Color(0xFF0091EA) : Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCustomTypeField() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextField(
        controller: customTypeCtrl,
        decoration: InputDecoration(
          hintText: "Nom de l'aliment...",
          filled: true, fillColor: Colors.blue.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildTimeTile() {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: selectedTime);
        if (t != null) setState(() => selectedTime = t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF0091EA)),
            const SizedBox(width: 8),
            Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    String finalType = isCustomType ? customTypeCtrl.text : (selectedType ?? "");
    if (finalType.isEmpty || qtyCtrl.text.isEmpty) return;

    final formattedTime = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance.collection('babies').doc(widget.babyId).collection('repas').add({
      'type': finalType,
      'quantite': "${qtyCtrl.text} $unit",
      'notes': noteCtrl.text,
      'heure': formattedTime,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }
}