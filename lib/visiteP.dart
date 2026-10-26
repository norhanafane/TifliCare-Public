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

  /       // AJOUT : On passe le nom complet au payload de la visite
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
