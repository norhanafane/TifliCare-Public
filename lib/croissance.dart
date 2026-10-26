import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';


 
class CroissancePage extends StatefulWidget {
  final String babyId;
  final Map babyData;

  const CroissancePage({super.key, required this.babyId, required this.babyData});

  @override
  State<CroissancePage> createState() => _CroissancePageState();
}

class _CroissancePageState extends State<CroissancePage> {

  String _formatAge(DateTime birth, DateTime measureDate) {
    final diff = measureDate.difference(birth);
    if (diff.inDays <= 0) return "À la naissance";
    if (diff.inDays < 7)  return "${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}";
    if (diff.inDays < 31) return "${(diff.inDays / 7).floor()} semaine${(diff.inDays / 7).floor() > 1 ? 's' : ''}";
    int months = (diff.inDays / 30.44).floor();
    if (months < 24) return "$months mois";
    int years = months ~/ 12;
    int rem   = months % 12;
    return rem == 0 ? "$years ans" : "$years ans $rem mois";
  }

  @override
  Widget build(BuildContext context) {
    DateTime birthDate;
    var raw = widget.babyData['dateNaissance'];
    if (raw is Timestamp)     birthDate = raw.toDate();
    else if (raw is String)   birthDate = DateTime.tryParse(raw.replaceAll('/', '-')) ?? DateTime.now();
    else                      birthDate = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Carnet de croissance",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("babies").doc(widget.babyId)
            .collection("measures").orderBy("date", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                if (docs.isNotEmpty) _buildSummaryCards(docs.first, birthDate),
                const SizedBox(height: 30),
                if (docs.isNotEmpty) _buildAdviceSection(docs.first, birthDate),
                const SizedBox(height: 35),
                Row(children: [
                  const Icon(Icons.history, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  const Text("Historique des mesures",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 15),
                _buildHistory(docs, birthDate),
              ],
            ),
          );
        },
      ),
    );
  }

 //header
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "${widget.babyData['prenom'] ?? ''} ${widget.babyData['nom'] ?? ''}",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text("Dernières mesures · ${widget.babyData['sexe']}",
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
        FloatingActionButton(
          onPressed: () => showDialog(
              context: context,
              builder: (_) => AddMeasureDialog(onSaved: _saveMeasure)),
          backgroundColor: const Color(0xFF0091EA),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }


  Widget _buildSummaryCards(QueryDocumentSnapshot doc, DateTime birth) {
    final d = doc.data() as Map<String, dynamic>;
    final date = d['date'] is Timestamp ? (d['date'] as Timestamp).toDate() : DateTime.now();
    final days = date.difference(birth).inDays;
    final sexe = widget.babyData['sexe'] ?? "Garçon";

    double getD(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final poids = getD(d['poids']);
    final taille = getD(d['taille']);
    final pc = getD(d['pc']);
    final imc = getD(d['imc']);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _measureCard("Poids", "$poids", "kg", Icons.monitor_weight_rounded,
            _getMedicalDiagnostic("Poids", poids, days, sexe), "Poids"),
        _measureCard("Taille", "$taille", "cm", Icons.straighten_rounded,
            _getMedicalDiagnostic("Taille", taille, days, sexe), "Taille"),
        _measureCard("Périmètre", "$pc", "cm", Icons.child_care_rounded,
            _getMedicalDiagnostic("PC", pc, days, sexe), "PC"),
        _measureCard("IMC (Corp.)", "$imc", "", Icons.bar_chart_rounded,
            _getMedicalDiagnostic("IMC", imc, days, sexe), "IMC"),
      ],
    );
  }

  Widget _measureCard(String title, String value, String unit, IconData icon,
      Map<String, dynamic> diag, String type) {
    final Color color = diag['status'] == 2 ? Colors.redAccent
        : (diag['status'] == 1 ? Colors.orangeAccent : const Color(0xFF4CB8C4));
    final posText = _percentileToParentText(diag['percentile']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          _buildMiniBar(diag['percentile'], color, posText),
        ],
      ),
    );
  }

  Widget _buildMiniBar(double val, Color color, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4, width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (val / 100).clamp(0.1, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w500)
        ),
      ],
    );
  }

// CONSEILS
  Widget _buildAdviceSection(QueryDocumentSnapshot doc, DateTime birth) {
    final d = doc.data() as Map<String, dynamic>;
    final date = d['date'] is Timestamp ? (d['date'] as Timestamp).toDate() : DateTime.now();
    final days = date.difference(birth).inDays;
    final sexe = widget.babyData['sexe'] ?? "Garçon";

    double getD(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);

    final indicators = [
      {"type": "Poids", "value": getD(d['poids'])},
      {"type": "Taille", "value": getD(d['taille'])},
      {"type": "PC", "value": getD(d['pc'])},
      {"type": "IMC", "value": getD(d['imc'])},
    ];

    final alerts = indicators.map((i) {
      final diag = _getMedicalDiagnostic(i["type"] as String, i["value"] as double, days, sexe);
      if (diag['status'] == 0) return null;
      var msg = _toParentMessage(i["type"] as String, diag['status'], diag['label'], diag['percentile']);
      msg['color'] = diag['status'] == 2 ? "red" : "orange";
      return msg;
    }).whereType<Map<String, dynamic>>().toList();

    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: const [
          Text("✨", style: TextStyle(fontSize: 20)),
          SizedBox(width: 15),
          Expanded(child: Text("Croissance parfaite, continuez ainsi !",
              style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14))),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text("Notes de santé", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        ...alerts.map((a) {
          final isCrit = a['color'] == "red";
          final accent = isCrit ? Colors.redAccent : Colors.orangeAccent;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(width: 6, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a["emoji"]!, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a["title"]!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: accent)),
                                  const SizedBox(height: 4),
                                  Text(a["advice"]!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
                                ],
                              ),
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
        }),
      ],
    );
  }

  // ── Historique
  Widget _buildHistory(List<QueryDocumentSnapshot> docs, DateTime birth) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, i) {
        final d    = docs[i].data() as Map<String, dynamic>;
        final date = (d['date'] as Timestamp).toDate();
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Âge : ${_formatAge(birth, date)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text("${date.day}/${date.month}/${date.year}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Divider(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _histItem(Icons.scale,     "${d['poids']} kg"),
                  _histItem(Icons.height,    "${d['taille']} cm"),
                  _histItem(Icons.face,      "${d['pc']} cm tête"),
                  _histItem(Icons.analytics, "Corpulence ${d['imc']}"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _histItem(IconData icon, String txt) => Row(children: [
    Icon(icon, size: 14, color: Colors.grey),
    const SizedBox(width: 4),
    Text(txt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
  ]);

  Future<void> _saveMeasure({
    required double poids, required double taille,
    required double pc, required DateTime date, String? notes,
  }) async {
    final tM  = taille / 100;
    final imc = double.parse((poids / (tM * tM)).toStringAsFixed(1));
    await FirebaseFirestore.instance
        .collection("babies").doc(widget.babyId)
        .collection("measures").add({
      "poids": poids, "taille": taille, "pc": pc,
      "imc": imc, "date": Timestamp.fromDate(date), "notes": notes ?? "",
    });
  }
}


//   AJOUT MESURE dialog
class AddMeasureDialog extends StatefulWidget {
  final Future<void> Function({
  required double poids, required double taille,
  required double pc, required DateTime date, String? notes,
  }) onSaved;

  const AddMeasureDialog({super.key, required this.onSaved});

  @override
  State<AddMeasureDialog> createState() => _AddMeasureDialogState();
}

class _AddMeasureDialogState extends State<AddMeasureDialog> {
  final poidsCtrl = TextEditingController();
  final tailleCtrl = TextEditingController();
  final pcCtrl    = TextEditingController();
  final notesCtrl = TextEditingController();
  DateTime? selectedDate;
  bool isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ajouter une mesure",
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                    constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                  ),
                ],
              ),

              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0091EA).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Color(0xFF0091EA), size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    "Entrez les mesures notées sur votre balance.",
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  )),
                ]),
              ),

              Row(children: [
                Expanded(child: _input("Poids (kg)", "ex : 7.5", poidsCtrl)),
                const SizedBox(width: 15),
                Expanded(child: _input("Taille (cm)", "ex : 67", tailleCtrl)),
              ]),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _input("Tour de tête (cm)", "ex : 42.5", pcCtrl)),
                  const SizedBox(width: 15),
                  Expanded(child: _datePicker()),
                ],
              ),
              const SizedBox(height: 15),
              _input("Remarques", "Ex : contrôle chez Dr Dupont…", notesCtrl, maxLines: 3),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0091EA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Enregistrer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl, maxLines: maxLines,
          keyboardType: maxLines == 1 ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true, fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0091EA), width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  Widget _datePicker() {
    final txt = selectedDate == null ? "jj/mm/aaaa"
        : "${selectedDate!.day.toString().padLeft(2,'0')}/${selectedDate!.month.toString().padLeft(2,'0')}/${selectedDate!.year}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Date de la mesure", style: TextStyle(fontSize: 14, color: Color(0xFF2D3142))),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          child: Container(
            height: 48, padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(txt, style: TextStyle(
                    color: selectedDate == null ? Colors.grey.shade400 : Colors.black, fontSize: 14)),
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _save() async {
    if (poidsCtrl.text.isEmpty || tailleCtrl.text.isEmpty ||
        pcCtrl.text.isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Veuillez remplir tous les champs avant de continuer.")));
      return;
    }
    setState(() => isLoading = true);
    try {
      await widget.onSaved(
        poids: double.parse(poidsCtrl.text),
        taille: double.parse(tailleCtrl.text),
        pc: double.parse(pcCtrl.text),
        date: selectedDate!, notes: notesCtrl.text,
      );
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Vérifiez les valeurs saisies et réessayez.")));
    } finally {
      setState(() => isLoading = false);
    }
  }
}
