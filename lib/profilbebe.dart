import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BabyProfilePage extends StatelessWidget {
  final String babyId;
  final Map<String, dynamic> babyData;

  const BabyProfilePage({super.key, required this.babyId, required this.babyData});


  String _calcAge(dynamic rawDate) {
    DateTime? birth;
    if (rawDate is Timestamp) birth = rawDate.toDate();
    else if (rawDate is String) birth = DateTime.tryParse(rawDate.replaceAll('/', '-'));
    if (birth == null) return "N/A";

    final now = DateTime.now();
    final diff = now.difference(birth);

    if (diff.inDays == 0) return "Naissance (aujourd'hui)";
    if (diff.inDays < 7)  return "${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()} semaine${(diff.inDays / 7).floor() > 1 ? 's' : ''}";

    int months = (diff.inDays / 30.44).floor();
    if (months < 24) return "$months mois";

    int years = months ~/ 12;
    int rem   = months % 12;
    return rem == 0 ? "$years ans" : "$years ans $rem mois";
  }

  String _formatBirthDate(dynamic rawDate) {
    if (rawDate is Timestamp) return DateFormat('dd/MM/yyyy').format(rawDate.toDate());
    if (rawDate is String)    return rawDate;
    return "N/A";
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF4CB8C4);
    final Color darkBlue    = const Color(0xFF3E5151);

    final bool isGirl = babyData['sexe']?.toString().toLowerCase() == 'feminin' ||
        babyData['sexe']?.toString().toLowerCase() == 'f';
    final Color sexColor = isGirl ? const Color(0xFFF06292) : const Color(0xFF42A5F5);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(
          "Dossier N°${babyId.toUpperCase().substring(0, 8)}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryColor, darkBlue])),
        ),
        elevation: 2
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfessionalHeader(sexColor, isGirl),
            const SizedBox(height: 25),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildSectionTitle("Scores de Vitalité & Mensurations", Icons.analytics),
                      _buildVitalStatsRow(),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Examen Clinique Détaillé", Icons.medical_services_outlined),
                      _buildEnhancedClinicalExam(),
                    ],
                  ),
                ),
                const SizedBox(width: 25),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSectionTitle("Gestes & Réanimation", Icons.emergency_share),
                      _buildEnhancedNeonatGestures(),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Nutrition", Icons.restaurant_menu),
                      _buildAlimentationCard(),
                      const SizedBox(height: 20),
                      _buildTracingFooterCard(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildProfessionalHeader(Color color, bool isGirl) {
    final String age       = _calcAge(babyData['dateNaissance']);
    final String birthDate = _formatBirthDate(babyData['dateNaissance']);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [

          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(isGirl ? Icons.face_3 : Icons.face_6, size: 48, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  isGirl ? "♀" : "♂",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(width: 25),


          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${babyData['prenom']} ${babyData['nom']?.toString().toUpperCase()}",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _badge("${babyData['sexe']}", color),
                    _badge("📍 ${babyData['lieuNaissance']}", Colors.grey),
                    _badge("🗓 $birthDate", Colors.blueGrey),
                  ],
                ),
              ],
            ),
          ),


          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Column(
              children: [
                Icon(Icons.child_care, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  "ÂGE ACTUEL",
                  style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  age,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVitalStatsRow() {
    final apgar = babyData['apgar'] ?? {};
    final m     = babyData['mensurations'] ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _apgarVisual(
              a1: _parseInt(apgar['1min']),
              a5: _parseInt(apgar['5min']),
              a10: _parseInt(apgar['10min']),
            ),
            _vDivider(),
            _dataColumn("POIDS",      "${m['poids']} g",  Colors.blue),
            _vDivider(),
            _dataColumn("TAILLE",     "${m['taille']} cm", Colors.blue),
            _vDivider(),
            _dataColumn("P. CRÂNIEN", "${m['pc']} cm",    Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _apgarVisual({required int a1, required int a5, required int a10}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "APGAR",
          style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _apgarBubble(a1,  "1'"),
            const SizedBox(width: 6),
            _apgarBubble(a5,  "5'"),
            const SizedBox(width: 6),
            _apgarBubble(a10, "10'"),
          ],
        ),
        const SizedBox(height: 6),
        _apgarProgressBar(a5),
      ],
    );
  }

  Widget _apgarBubble(int score, String label) {
    final Color bg = _apgarColor(score);
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg.withOpacity(0.15),
            border: Border.all(color: bg, width: 2.5),
          ),
          child: Center(
            child: Text(
              score >= 0 ? "$score" : "—",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: bg),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _apgarProgressBar(int score) {
    final Color c = _apgarColor(score);
    final double pct = score < 0 ? 0 : (score / 10).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_apgarLabel(score), style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Container(
          width: 138, height: 5,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  Color _apgarColor(int score) {
    if (score < 0)  return Colors.grey;
    if (score <= 3) return Colors.red;
    if (score <= 6) return Colors.orange;
    return Colors.green;
  }

  String _apgarLabel(int score) {
    if (score < 0)  return "N/A";
    if (score <= 3) return "DÉPRESSION SÉVÈRE";
    if (score <= 6) return "DÉPRESSION MODÉRÉE";
    return "BON ÉTAT";
  }

  int _parseInt(dynamic v) {
    if (v == null) return -1;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? -1;
  }


  Widget _buildEnhancedClinicalExam() {
    final exam = babyData['examenPhysique'] ?? {};
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _buildExamCategory("Tête & Cou", [
            _statusRow("Yeux normaux",    exam['Yeux normaux']),
            _statusRow("Oreilles normales", exam['Oreilles normales']),
          ]),
          _buildExamCategory("Cardio-Respiratoire", [
            _statusRow("Souffle cardiaque",  exam['Souffle cardiaque'],  isDanger: true),
            _statusRow("Hépatomégalie",      exam['Hépatomégalie'],      isDanger: true),
            _statusRow("Splénomégalie",      exam['Splénomégalie'],      isDanger: true),
          ]),
          _buildExamCategory("Membres & Digestif", [
            _statusRow("Hanches normales",       exam['Hanches normales']),
            _statusRow("Pieds/Mains normaux",    exam['Pieds et mains normaux']),
            _statusRow("Perméabilité anale",     exam['Perméabilité anale']),
            _statusRow("Malform. Anorectale",    exam['Malformation anorectale'], isDanger: true),
          ]),
          _buildExamCategory("Autres", [
            _statusRow("Génitaux normaux",       exam['Organes génitaux normaux']),
            _statusRow("Malformations visibles", exam['Malformations visibles'],  isDanger: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildEnhancedNeonatGestures() {
    final neo = babyData['examenNeonat'] ?? {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF2D3436), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _gestureRow("Cri immédiat",      neo['Cri immédiat'],           icon: Icons.record_voice_over),
          _gestureRow("Aspiration",        neo['Aspiration']),
          _gestureRow("Réanimation",       neo['Réanimation nécessaire'], isDanger: true),
          _gestureRow("Ventilation Masque", neo['Ventilation au masque']),
          _gestureRow("Massage Cardiaque", neo['Massage cardiaque'],      isDanger: true),
          _gestureRow("Intubation",        neo['Intubation'],             isDanger: true),
          _gestureRow("Adrénaline",        neo['Adrénaline'],             isDanger: true),
        ],
      ),
    );
  }


  Widget _statusRow(String label, dynamic value, {bool isDanger = false}) {
    bool isTrue = value == true;
    Color color = isDanger
        ? (isTrue ? Colors.red : Colors.green)
        : (isTrue ? Colors.green : Colors.red);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(isTrue ? Icons.lens : Icons.radio_button_unchecked, size: 12, color: color),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text("${isTrue ? "OUI" : "NON"}",
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _gestureRow(String label, dynamic value,
      {bool isDanger = false, IconData icon = Icons.check_circle_outline}) {
    bool active = value == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? (isDanger ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2))
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: active ? (isDanger ? Colors.redAccent : Colors.lightBlue) : Colors.grey,
              size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade500,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  Widget _buildExamCategory(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4CB8C4))),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  Widget _dataColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildAlimentationCard() {
    final alim = babyData['alimentation'] ?? {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alim['type'] ?? 'N/C',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
          const SizedBox(height: 10),
          const Text("Raison si non-exclusif :", style: TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            alim['raisonNonExclusive'] == "" ? "Aucune mentionnée" : alim['raisonNonExclusive'],
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTracingFooterCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text("Particien : ${babyData['creePar']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 5),
          Text(
            "Enregistré le : ${babyData['createdAt'] != null ? DateFormat('dd/MM/yyyy HH:mm').format((babyData['createdAt'] as Timestamp).toDate()) : 'N/A'}",
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _badge(String txt, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(txt, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)));

  Widget _vDivider() => const VerticalDivider(color: Colors.black12, thickness: 1);

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CB8C4)),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E5151))),
        ],
      ),
    );
  }
}