import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';


class _CheckItem {
  final String label;
  final bool defaultValue;
  const _CheckItem(this.label, {this.defaultValue = false});
}


class _CheckSection {
  final String title;
  final String storageKey;
  final List<_CheckItem> items;
  final String? note;
  const _CheckSection(this.title, this.storageKey, this.items, {this.note});
}

class _VisitConfig {
  final bool hasPc;
  final bool hasImc;
  final bool hasTemperature;
  final bool hasFcFr;
  final bool hasAlimentation;
  final bool hasAlimentationNote;
  final bool hasAlimentationChecks;
  final bool hasTroubleComportement;
  final List<_CheckSection> checkSections;
  final List<String> freeTextFields;
  final List<String> warnings;

  const _VisitConfig({
    this.hasPc = true,
    this.hasImc = false,
    this.hasTemperature = false,
    this.hasFcFr = false,
    this.hasAlimentation = false,
    this.hasAlimentationNote = false,
    this.hasAlimentationChecks = false,
    this.hasTroubleComportement = false,
    this.checkSections = const [],
    this.freeTextFields = const [],
    this.warnings = const [],
  });
}



const _configs = <String, _VisitConfig>{

  // ── 8 JOURS ────────────────────────────────────────────────────
  "8j": _VisitConfig(
    hasTemperature: true, hasFcFr: true, hasPc: true,
    hasAlimentation: true,
    checkSections: [
      _CheckSection("Examen clinique", "examClinic", [
        _CheckItem("Ictère"),
        _CheckItem("Pâleur"),
        _CheckItem("Souffle cardiaque"),
        _CheckItem("Pouls fémoraux perçus"),
        _CheckItem("Luxation des hanches"),
        _CheckItem("Testicules dans les bourses"),
        _CheckItem("Fontanelles normales", defaultValue: true),
      ]),
      _CheckSection("Examen neurologique", "examNeuro", [
        _CheckItem("État d'éveil normal",           defaultValue: true),
        _CheckItem("Mobilité normale",               defaultValue: true),
        _CheckItem("Attitude en quadri flexion",     defaultValue: true),
        _CheckItem("Retour en flexion des membres",  defaultValue: true),
        _CheckItem("Épreuve tiré-assis normale",     defaultValue: true),
        _CheckItem("Épreuve de redressement",        defaultValue: true),
        _CheckItem("Réaction aux stimuli sonores",   defaultValue: true),
        _CheckItem("Tonus axial normal",             defaultValue: true),
        _CheckItem("Grasping réflexe",               defaultValue: true),
        _CheckItem("Allongement croisé",             defaultValue: true),
        _CheckItem("Réflexe de Moro",                defaultValue: true),
        _CheckItem("Paralysie du plexus brachial"),
      ]),
    ],
    freeTextFields: ["autresAnomalies|Autres anomalies|edit_note"],
  ),

  // ── 1 MOIS ──────────────────────────────────────────
  "standard": _VisitConfig(
    hasPc: true, hasAlimentation: true,
    checkSections: [
      _CheckSection("Examen clinique", "examClinic", [
        _CheckItem("Ictère persistant"),
        _CheckItem("Fontanelles normales",       defaultValue: true),
        _CheckItem("Souffle cardiaque"),
        _CheckItem("Pouls fémoraux perçus",      defaultValue: true),
        _CheckItem("Luxation de la hanche"),
        _CheckItem("Testicules dans les bourses",defaultValue: true),
      ]),
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Tient sa tête quelques secondes (tiré-assis)"),
        _CheckItem("Décolle sa tête en position ventrale"),
        _CheckItem("Grasping réflexe"),
        _CheckItem("Accroche le regard"),
        _CheckItem("Réagit au bruit (hochet)"),
      ]),
    ],
    freeTextFields: [
      "motif|Motif de consultation|help_outline",
      "resume|Résumé de l'examen|summarize",
      "traitement|Prise en charge / Traitement|medical_services",
    ],
  ),

  // ── 2 MOIS ─────────────────────────────────────────────────────
  "2mois": _VisitConfig(
    hasPc: true, hasAlimentation: true,
    checkSections: [
      _CheckSection("Examen clinique", "examClinic", [
        _CheckItem("Fontanelles normales",       defaultValue: true),
        _CheckItem("Anomalies oculaires"),
        _CheckItem("Anomalies auditives"),
        _CheckItem("Souffle cardiaque"),
        _CheckItem("Testicules dans les bourses",defaultValue: true),
        _CheckItem("Luxation de la hanche"),
      ], note: "* Si anomalies auditives → faire PEA"),
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Tenue de la tête"),
        _CheckItem("Tourne la tête vers une source sonore"),
        _CheckItem("Préhension au contact"),
        _CheckItem("Vocalise (gazouillis)"),
        _CheckItem("Sourire réponse"),
        _CheckItem("Suit des yeux"),
      ]),
    ],
  ),

  // ── 4 MOIS ─────────────────────────────────────────────────────
  "4mois": _VisitConfig(
    hasPc: true, hasAlimentation: true,
    checkSections: [
      _CheckSection("Examen clinique", "examClinic", [
        _CheckItem("Fontanelles normales",    defaultValue: true),
        _CheckItem("Souffle cardiaque"),
        _CheckItem("Ectopie testiculaire"),
        _CheckItem("Cicatrice BCG présente",  defaultValue: true),
      ], note: "* Si anomalie auditive → faire PEA"),
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Tient la tête droite en position assise"),
        _CheckItem("Retournement dos-ventre"),
        _CheckItem("Placé sur le ventre, redresse la tête"),
        _CheckItem("Regarde ses mains"),
        _CheckItem("Tourne la tête à l'appel"),
      ]),
    ],
  ),

  // ── 6 MOIS ─────────────────────────────────────────────────────
  "6mois": _VisitConfig(
    hasPc: true, hasAlimentationChecks: true,
    checkSections: [
      _CheckSection("Mode d'alimentation", "alimentationMode", [
        _CheckItem("Allaitement maternel",             defaultValue: true),
        _CheckItem("Allaitement mixte"),
        _CheckItem("Allaitement artificiel"),
        _CheckItem("Diversification alimentaire débutée"),
      ]),
      _CheckSection("Examen clinique", "examClinic", [
        _CheckItem("Fontanelles normales",  defaultValue: true),
        _CheckItem("Souffle cardiaque"),
        _CheckItem("Ectopie testiculaire"),
        _CheckItem("Cicatrice BCG présente",defaultValue: true),
      ]),
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Retournement dos-ventre"),
        _CheckItem("Saisit un objet à sa vue ou au contact"),
        _CheckItem("Tourne la tête à l'appel"),
        _CheckItem("Rit et vocalise"),
      ], note: "* Si anomalie auditive → faire PEA"),
    ],
  ),

  // ── 9 MOIS ─────────────────────────────────────────────────────
  "9mois": _VisitConfig(
    hasPc: true, hasAlimentationChecks: true,
    checkSections: [
      _CheckSection("Mode d'alimentation", "alimentationMode", [
        _CheckItem("Allaitement maternel",    defaultValue: true),
        _CheckItem("Allaitement mixte"),
        _CheckItem("Allaitement artificiel"),
        _CheckItem("Diversification alimentaire", defaultValue: true),
      ]),
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Station assise sans appui"),
        _CheckItem("Roule sur lui-même"),
        _CheckItem("Station debout avec appui"),
        _CheckItem("Préhension pouce-index"),
        _CheckItem("Syllabes répétées (dada-papa-mama)"),
        _CheckItem("Langage gestuel (tape des mains, dit au revoir)"),
        _CheckItem("Peur du visage étranger"),
      ], note: "* Si anomalies auditives → faire PEA"),
    ],
  ),

  // ── 12 MOIS ────────────────────────────────────────────────────
  "12mois": _VisitConfig(
    hasPc: true, hasImc: true, hasAlimentationChecks: true,
    checkSections: [
      _CheckSection("Mode d'alimentation", "alimentationMode", [
        _CheckItem("Allaitement maternel"),
        _CheckItem("Allaitement mixte"),
        _CheckItem("Allaitement artificiel"),
        _CheckItem("Diversification alimentaire", defaultValue: true),
      ]),
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Debout sans appui ou marche avec appui"),
        _CheckItem("Préhension fine pouce-index"),
        _CheckItem("Jette un objet présenté"),
        _CheckItem("Dit 2 à 3 mots signifiants (hors papa/mama)"),
        _CheckItem("Comprend un ordre simple"),
      ]),
    ],
    warnings: ["⚠️ Éviter l'exposition aux écrans (TV, tablettes, smartphones)"],
  ),

  // ── 18 MOIS ────────────────────────────────────────────────────
  "18mois": _VisitConfig(
    hasPc: true, hasImc: true, hasAlimentationNote: true,
    checkSections: [
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Marche acquise"),
        _CheckItem("Peut courir mais tombe souvent"),
        _CheckItem("Monte l'escalier avec aide"),
        _CheckItem("Construit une tour de 2 cubes"),
        _CheckItem("Sait tenir sa cuillère"),
        _CheckItem("Dit 8 à 10 mots signifiants"),
        _CheckItem("Peut combiner deux mots"),
      ]),
      _CheckSection("Recherche signes TSA", "signesTSA", [
        _CheckItem("Contact oculaire avec l'examinateur",   defaultValue: true),
        _CheckItem("Regarde l'objet pointé par l'index",    defaultValue: true),
        _CheckItem("Pointe son index vers un objet",        defaultValue: true),
        _CheckItem("Peu réactif / retrait social / peu d'émotions"),
        _CheckItem("Comportements répétitifs"),
        _CheckItem("Capable de construire une tour de cubes", defaultValue: true),
      ]),
    ],
    freeTextFields: ["examCliniqueNote|Résumé examen clinique|medical_information"],
  ),

  // ── 24 MOIS ────────────────────────────────────────────────────
  "24mois": _VisitConfig(
    hasPc: true, hasImc: true, hasAlimentationNote: true,
    checkSections: [
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Peut courir"),
        _CheckItem("Monte et descend l'escalier marche par marche"),
        _CheckItem("Tape dans un ballon"),
        _CheckItem("Ouvre et ferme une porte"),
        _CheckItem("Construit une tour de 6 à 8 cubes"),
        _CheckItem("Se nomme par son prénom"),
        _CheckItem("Fait des phrases de 3 mots"),
        _CheckItem("Peut manger seul"),
        _CheckItem("Reconnaît les différentes parties de son corps"),
        _CheckItem("Propreté diurne"),
      ]),
    ],
    freeTextFields: ["examCliniqueNote|Résumé examen clinique|medical_information"],
  ),

  // ── 3 ANS ──────────────────────────────────────────────────────
  "3ans": _VisitConfig(
    hasPc: true, hasImc: true,
    hasAlimentationNote: true, hasTroubleComportement: true,
    checkSections: [
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Monte l'escalier en alternant les pieds"),
        _CheckItem("Copie un cercle"),
        _CheckItem("Construit une tour de 9 cubes"),
        _CheckItem("Maîtrise du langage (je, moi)"),
        _CheckItem("Reconnaît 3 à 4 couleurs"),
        _CheckItem("Peut compter jusqu'à 6"),
        _CheckItem("Propreté diurne et nocturne"),
      ]),
    ],
  ),

  // ── 4 ANS ──────────────────────────────────────────────────────
  "4ans": _VisitConfig(
    hasPc: true, hasImc: true, hasAlimentationNote: true,
    checkSections: [
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Court"),
        _CheckItem("Descend l'escalier en alternant les pieds"),
        _CheckItem("Mange seul proprement"),
        _CheckItem("Construit une tour de 10 cubes"),
      ]),
    ],
  ),

  // ── 5 ANS ──────────────────────────────────────────────────────
  "5ans": _VisitConfig(
    hasPc: true, hasImc: true, hasAlimentationNote: true,
    checkSections: [
      _CheckSection("Développement psychomoteur", "devPsycho", [
        _CheckItem("Court avec aisance"),
        _CheckItem("Sait compter jusqu'à 20 et plus"),
        _CheckItem("Peut écrire certaines lettres"),
        _CheckItem("S'oriente dans le temps et l'espace"),
        _CheckItem("Raconte des histoires"),
        _CheckItem("Autonomie totale (s'habille seul)"),
      ]),
    ],
  ),
};



class PediatricVisitAdmin extends StatefulWidget {
  final String babyId;
  final Map<String, dynamic> doctorData;
  const PediatricVisitAdmin(
      {super.key, required this.babyId, required this.doctorData});

  @override
  State<PediatricVisitAdmin> createState() => _PediatricVisitAdminState();
}

class _PediatricVisitAdminState extends State<PediatricVisitAdmin> {
  final Color primaryBlue  = const Color(0xFF4CB8C4);
  final Color successGreen = const Color(0xFF4CAF50);
  StreamSubscription? _btSubscription;
  BluetoothDevice? _connectedDevice;
  bool _isDataCaptured = false;

  final List<Map<String, dynamic>> visitesSystematiques = [
    {"id": "sys_8_jours",  "label": "8 jours",  "type": "8j"},
    {"id": "sys_1_mois",   "label": "1 mois",   "type": "standard"},
    {"id": "sys_2_mois",   "label": "2 mois",   "type": "2mois"},
    {"id": "sys_4_mois",   "label": "4 mois",   "type": "4mois"},
    {"id": "sys_6_mois",   "label": "6 mois",   "type": "6mois"},
    {"id": "sys_9_mois",   "label": "9 mois",   "type": "9mois"},
    {"id": "sys_12_mois",  "label": "12 mois",  "type": "12mois"},
    {"id": "sys_18_mois",  "label": "18 mois",  "type": "18mois"},
    {"id": "sys_24_mois",  "label": "24 mois",  "type": "24mois"},
    {"id": "sys_3_ans",    "label": "3 ans",    "type": "3ans"},
    {"id": "sys_4_ans",    "label": "4 ans",    "type": "4ans"},
    {"id": "sys_5_ans",    "label": "5 ans",    "type": "5ans"},
  ];

  // bluetooth

  void _setupIoTListener(TextEditingController poidsCtrl, TextEditingController tailleCtrl, Function setModalState) async {
    final instance = FlutterWebBluetooth.instance;
    if (!instance.isBluetoothApiSupported) return;
    try {
      _connectedDevice = await instance.requestDevice(
        RequestOptionsBuilder.acceptAllDevices(
          optionalServices: ["4fafc201-1fb5-459e-8fcc-c5c9c331914b"],
        ),
      );
      await _connectedDevice!.connect();
      final services = await _connectedDevice!.discoverServices();
      final svc = services.firstWhere((s) => s.uuid == "4fafc201-1fb5-459e-8fcc-c5c9c331914b");
      final charac = await svc.getCharacteristic("beb5483e-36e1-4688-b7f5-ea07361b26a8");

      await charac.startNotifications();

      _btSubscription = charac.value.listen((v) {
        String rawData = utf8.decode(v.buffer.asUint8List()).trim();


        if (rawData.contains('|')) {
          List<String> parts = rawData.split('|');


          String rawPoids = parts[0].replaceAll('kg', '').replaceAll('g', '').trim();
          String rawTaille = parts[1].replaceAll('cm', '').trim();

          double valPoids = double.tryParse(rawPoids) ?? 0.0;
          double valTaille = double.tryParse(rawTaille) ?? 0.0;


          if (valPoids > 0.5 && valTaille > 5.0) {
            setModalState(() {
              poidsCtrl.text = rawPoids;
              tailleCtrl.text = rawTaille;
              _isDataCaptured = true;
            });
            _stopBluetoothListening();
          }
        }
      });
    } catch (e) {
      debugPrint("Bluetooth error: $e");
    }
  }


  void _stopBluetoothListening() {
    _btSubscription?.cancel();
    _btSubscription = null;
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Suivi infantile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('babies')
            .doc(widget.babyId)
            .collection('visites')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final doneVisits = {
            for (var d in snap.data!.docs)
              d['id']: d.data() as Map<String, dynamic>
          };
          final allDocs = snap.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeaderSection("Visites Systématiques", Icons.assignment_turned_in),
              const SizedBox(height: 10),
              ...visitesSystematiques.map((v) {
                final isDone = doneVisits.containsKey(v["id"]);
                return _buildVisitCard(
                  v["id"], v["label"], isDone, true,
                  doneVisits[v["id"]], visitType: v["type"],
                );
              }),
              const SizedBox(height: 30),
              _buildHeaderSection("Entre-consultations", Icons.medical_services),
              const SizedBox(height: 10),
              ...allDocs.where((d) => !d.id.startsWith("sys_")).map((d) {
                final data = d.data() as Map<String, dynamic>;
                return _buildVisitCard(
                  d.id, data['title'] ?? "Consultation libre",
                  true, false, data, visitType: "libre",
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(
          id: "free_${DateTime.now().millisecondsSinceEpoch}",
          title: "Consultation libre",
          visitType: "standard",
          isSystematic: false,
        ),
        label: const Text("Nouvelle Consultation"),
        icon: const Icon(Icons.add),
        backgroundColor: primaryBlue,
      ),
    );
  }


  Widget _buildHeaderSection(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: Colors.blueGrey, size: 20),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    ]);
  }

  Widget _buildVisitCard(String id, String title, bool isDone,
      bool isSystematic, Map<String, dynamic>? data,
      {String visitType = "standard"}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: isDone ? successGreen : Colors.grey.shade300, width: 1.5),
      ),
      color: isDone ? successGreen.withOpacity(0.05) : Colors.white,
      child: ListTile(
        leading: Icon(
            isDone ? Icons.check_circle : Icons.pending_actions,
            color: isDone ? successGreen : Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isDone
            ? Text("Fait le ${data?['date']} | Voir détails")
            : const Text("Cliquer pour remplir le formulaire"),
        trailing: Icon(isDone ? Icons.visibility : Icons.edit, size: 20),
        onTap: () => _openForm(
          id: id, title: title, visitType: visitType,
          isSystematic: isSystematic, existingData: data,
        ),
      ),
    );
  }


  void _openForm({
    required String id,
    required String title,
    required String visitType,
    required bool isSystematic,
    Map<String, dynamic>? existingData,
  }) {
    final bool isReadOnly = existingData != null;
    final cfg = _configs[visitType] ?? _configs["standard"]!;

    final poids       = TextEditingController(text: existingData?['poids']       ?? '');
    final taille      = TextEditingController(text: existingData?['taille']      ?? '');
    final pc          = TextEditingController(text: existingData?['pc']          ?? '');
    final imc         = TextEditingController(text: existingData?['imc']         ?? '');
    final temperature = TextEditingController(text: existingData?['temperature'] ?? '');
    final fc          = TextEditingController(text: existingData?['fc']          ?? '');
    final fr          = TextEditingController(text: existingData?['fr']          ?? '');
    final conclusion  = TextEditingController(text: existingData?['conclusion']  ?? '');
    final alimentationNote     = TextEditingController(text: existingData?['alimentationNote']     ?? '');
    final troubleComportement  = TextEditingController(text: existingData?['troubleComportement']  ?? '');


    final Map<String, TextEditingController> freeCtrls = {
      for (final f in cfg.freeTextFields)
        f.split('|')[0]: TextEditingController(
            text: existingData?[f.split('|')[0]] ?? '')
    };


    String alimentation = existingData?['alimentation'] ?? 'Maternel';

    final Map<String, Map<String, bool>> checks = {
      for (final s in cfg.checkSections)
        s.storageKey: {
          for (final item in s.items)
            item.label: existingData?[s.storageKey]?[item.label] ?? item.defaultValue
        }
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          expand: false,
          builder: (ctx, scroll) => SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Center(child: Container(
                  width: 50, height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                )),
                const SizedBox(height: 20),


                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: isReadOnly ? successGreen : primaryBlue))),
                    if (isReadOnly)
                      Chip(
                        label: const Text("HISTORIQUE"),
                        backgroundColor: successGreen.withOpacity(0.1),
                        labelStyle:
                        TextStyle(color: successGreen, fontSize: 10),
                      ),
                  ],
                ),
                if (isReadOnly)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Enregistré le ${existingData!['date']} par ${existingData['praticien']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                const Divider(),


                _sectionTitle("Mesures anthropométriques"),
                  if (!isReadOnly) _buildIoTWidget(poids, taille, setModal),
                Row(children: [
                  Expanded(child: _field(poids, "Poids (${visitType == '8j' ? 'g' : 'Kg'})", Icons.monitor_weight, isReadOnly)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(taille, "Taille (cm)", Icons.straighten, isReadOnly)),
                ]),


                if (cfg.hasPc) ...[
                  if (cfg.hasImc)
                    Row(children: [
                      Expanded(child: _field(pc,  "Périmètre crânien (cm)", Icons.face,      isReadOnly)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(imc, "IMC",                    Icons.calculate,  isReadOnly)),
                    ])
                  else
                    _field(pc, "Périmètre crânien (cm)", Icons.face, isReadOnly),
                ],


                if (cfg.hasTemperature) ...[
                  Row(children: [
                    Expanded(child: _field(temperature, "Température (°C)", Icons.thermostat, isReadOnly)),
                    const SizedBox(width: 10),
                    if (cfg.hasFcFr) ...[
                      Expanded(child: _field(fc, "FC (bpm)", Icons.favorite_border, isReadOnly)),
                    ],
                  ]),
                  if (cfg.hasFcFr)
                    _field(fr, "FR (cycles/min)", Icons.air, isReadOnly),
                ],


                if (cfg.hasAlimentation) ...[
                  _sectionTitle("Alimentation"),
                  _alimentationDropdown(alimentation, isReadOnly,
                          (v) => setModal(() => alimentation = v!)),
                ],


                if (cfg.hasAlimentationNote) ...[
                  _sectionTitle("Alimentation"),
                  _field(alimentationNote, "Notes sur l'alimentation",
                      Icons.restaurant, isReadOnly),
                ],


                if (cfg.hasTroubleComportement) ...[
                  _sectionTitle("Troubles du comportement"),
                  _field(troubleComportement,
                      "Agitation, agressivité, hyperactivité, TOC...",
                      Icons.psychology, isReadOnly, maxLines: 2),
                ],


                for (final section in cfg.checkSections) ...[
                  _sectionTitle(section.title),
                  ...section.items.map((item) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.label, style: const TextStyle(fontSize: 14)),
                    value: checks[section.storageKey]![item.label],
                    activeColor: successGreen,
                    onChanged: isReadOnly ? null : (v) =>
                        setModal(() => checks[section.storageKey]![item.label] = v!),
                  )),
                  if (section.note != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(section.note!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.orange,
                              fontStyle: FontStyle.italic)),
                    ),
                ],


                ...cfg.freeTextFields.expand((entry) {
                  final parts = entry.split('|');
                  return [
                    _sectionTitle(parts[1]),
                    _field(freeCtrls[parts[0]]!, parts[1],
                        _iconFromName(parts[2]), isReadOnly),
                  ];
                }),


                for (final w in cfg.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(w, style: const TextStyle(
                        fontSize: 11, color: Colors.deepOrange,
                        fontStyle: FontStyle.italic)),
                  ),


                _sectionTitle("Conclusion"),
                _field(conclusion, "Diagnostic et observations",
                    Icons.edit_note, isReadOnly, maxLines: 3),

                const SizedBox(height: 30),


                if (!isReadOnly)
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: () async {
                        try {
                          // 1. Récupérer l'ID du praticien connecté
                          String uid = FirebaseAuth.instance.currentUser!.uid;

                          // 2. Chercher ses informations dans la collection 'users'
                          DocumentSnapshot userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get();

                          String praticienNomComplet = "Praticien Inconnu";

                          if (userDoc.exists) {
                            String nom = userDoc.get('nom') ?? "";
                            String prenom = userDoc.get('prenom') ?? "";
                            praticienNomComplet = "Dr. $nom $prenom".trim();

                            if (praticienNomComplet == "Dr.") {
                              praticienNomComplet = "Dr. Inconnu";
                            }
                          }

                          // 3. Envoyer les données à enregistrer
                          await _saveVisite(id, title, {
                            'poids': poids.text,
                            'taille': taille.text,
                            'pc': pc.text,
                            if (cfg.hasImc) 'imc': imc.text,
                            if (cfg.hasTemperature) 'temperature': temperature.text,
                            if (cfg.hasFcFr) ...{'fc': fc.text, 'fr': fr.text},
                            if (cfg.hasAlimentation) 'alimentation': alimentation,
                            if (cfg.hasAlimentationNote) 'alimentationNote': alimentationNote.text,
                            if (cfg.hasTroubleComportement) 'troubleComportement': troubleComportement.text,
                            ...checks,
                            for (final e in freeCtrls.entries) e.key: e.value.text,
                            'conclusion': conclusion.text,

                            // AJOUT : On passe le nom complet au payload de la visite
                            'praticien': praticienNomComplet,
                          });

                          Navigator.pop(ctx); // Ferme le modal après enregistrement complet
                        } catch (e) {
                          print("Erreur lors de la récupération du médecin : $e");
                        }
                      },
                      child: const Text("Enregistrer la visite",
                          style: TextStyle(
                              color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text("Fermer l'historique"),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _saveVisite(
      String id, String title, Map<String, dynamic> data) async {
    try {
      final now = DateTime.now();
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection('babies')
          .doc(widget.babyId)
          .collection('visites')
          .doc(id)
          .set({
        ...data,
        'id': id,
        'title': title,

        'praticien': data['praticien'] ?? widget.doctorData['nom'] ?? "Dr. Connecté",
        'createdAt': FieldValue.serverTimestamp(),
        'date': dateStr,
      });

      final tNum = double.tryParse(data['taille'].toString()) ?? 0.0;
      final pRaw = double.tryParse(data['poids'].toString()) ?? 0.0;
      final pKg  = pRaw > 100 ? pRaw / 1000 : pRaw;
      final imc  = (tNum > 0 && pKg > 0)
          ? double.parse((pKg / ((tNum / 100) * (tNum / 100))).toStringAsFixed(1))
          : 0.0;

      await FirebaseFirestore.instance
          .collection('babies')
          .doc(widget.babyId)
          .collection('measures')
          .add({
        'createdAt': FieldValue.serverTimestamp(),
        'date':   Timestamp.now(),
        'taille': tNum,
        'poids':  pKg,
        'pc':     double.tryParse(data['pc'].toString()) ?? 0.0,
        'imc':    imc,
        'notes':  data['conclusion'] ?? "",
      });

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Consultation enregistrée avec succès")),
        );
      }
    } catch (e) {
      debugPrint("Erreur sauvegarde : $e");
    }
  }

  Widget _buildIoTWidget(TextEditingController poids, TextEditingController taille, Function setModalState) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDataCaptured ? successGreen.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isDataCaptured ? successGreen.withOpacity(0.4) : primaryBlue.withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(children: [
          Icon(_isDataCaptured ? Icons.check_circle : Icons.bluetooth, color: _isDataCaptured ? successGreen : primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isDataCaptured
                  ? "Mesures capturées et figées avec succès !"
                  : "Balance connectée : Posez le nourrisson puis cliquez pour capturer.",
              style: TextStyle(fontSize: 12, color: _isDataCaptured ? Colors.green.shade900 : Colors.blueGrey),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _isDataCaptured
              ? OutlinedButton.icon(
            onPressed: () {
              setModalState(() {
                _isDataCaptured = false;
                poids.clear();
                taille.clear();
              });
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Reprendre la mesure"),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
          )
              : ElevatedButton.icon(
            onPressed: () => _setupIoTListener(poids, taille, setModalState),
            icon: const Icon(Icons.sync, size: 18, color: Colors.white),
            label: const Text("Capturer Poids et Taille", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]),
    );
  }
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.blueGrey)),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      bool readOnly, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: maxLines == 1 ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon,
              size: 20, color: readOnly ? successGreen : primaryBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor:
          readOnly ? Colors.green.withOpacity(0.02) : Colors.grey[50],
        ),
      ),
    );
  }

  Widget _alimentationDropdown(
      String value, bool readOnly, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabled: !readOnly,
        ),
        items: ["Maternel", "Mixte", "Artificiel"]
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: readOnly ? null : onChanged,
      ),
    );
  }

  IconData _iconFromName(String name) {
    const map = <String, IconData>{
      "edit_note":            Icons.edit_note,
      "help_outline":         Icons.help_outline,
      "summarize":            Icons.summarize,
      "medical_services":     Icons.medical_services,
      "medical_information":  Icons.medical_information,
      "restaurant":           Icons.restaurant,
      "psychology":           Icons.psychology,
    };
    return map[name] ?? Icons.notes;
  }
}