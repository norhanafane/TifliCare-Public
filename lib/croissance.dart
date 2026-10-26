import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// ─────────────────────────────────────────────
// TABLES OMS RÉELLES (LMS) — 0 à 60 mois
// Chaque entrée : [mois, L, M, S]
// Source : WHO Child Growth Standards
// L = Box-Cox power, M = médiane, S = coefficient de variation
// ─────────────────────────────────────────────

// ── POIDS garçons (kg)
const List<List<double>> _whoPoidsGarcon = [
  [0,0.3487,3.3464,0.14602],[1,0.2297,4.4709,0.13395],[2,0.197,5.5675,0.12385],
  [3,0.1832,6.3762,0.11559],[4,0.1686,7.0023,0.10953],[5,0.1540,7.5105,0.10475],
  [6,0.1419,7.9340,0.10082],[7,0.1335,8.2970,0.09762],[8,0.1265,8.6151,0.09500],
  [9,0.1200,8.9014,0.09276],[10,0.1137,9.1649,0.09078],[11,0.1068,9.4122,0.08898],
  [12,0.0993,9.6479,0.08724],[13,0.0930,9.8749,0.08539],[14,0.0879,10.0953,0.08349],
  [15,0.0839,10.3108,0.08175],[16,0.0804,10.5228,0.08014],[17,0.0765,10.7319,0.07864],
  [18,0.0723,10.9385,0.07718],[19,0.0681,11.1430,0.07570],[20,0.0641,11.3462,0.07421],
  [21,0.0604,11.5486,0.07269],[22,0.0570,11.7504,0.07117],[23,0.0538,11.9514,0.06966],
  [24,0.0509,12.1515,0.06816],[25,0.0481,12.3502,0.06668],[26,0.0454,12.5466,0.06525],
  [27,0.0428,12.7401,0.06388],[28,0.0403,12.9303,0.06256],[29,0.0379,13.1170,0.06130],
  [30,0.0357,13.3000,0.06008],[31,0.0336,13.4793,0.05893],[32,0.0317,13.6553,0.05782],
  [33,0.0299,13.8279,0.05676],[34,0.0283,13.9973,0.05574],[35,0.0267,14.1634,0.05476],
  [36,0.0253,14.3262,0.05382],[37,0.0240,14.4858,0.05292],[38,0.0228,14.6423,0.05205],
  [39,0.0217,14.7957,0.05121],[40,0.0206,14.9461,0.05040],[41,0.0196,15.0935,0.04962],
  [42,0.0186,15.2380,0.04887],[43,0.0177,15.3797,0.04814],[44,0.0168,15.5186,0.04744],
  [45,0.0159,15.6549,0.04676],[46,0.0151,15.7886,0.04611],[47,0.0143,15.9198,0.04549],
  [48,0.0136,16.0487,0.04489],[49,0.0128,16.1753,0.04431],[50,0.0121,16.2995,0.04376],
  [51,0.0114,16.4214,0.04323],[52,0.0107,16.5413,0.04272],[53,0.0100,16.6591,0.04224],
  [54,0.0094,16.7749,0.04178],[55,0.0088,16.8888,0.04134],[56,0.0082,17.0009,0.04092],
  [57,0.0076,17.1113,0.04052],[58,0.0070,17.2201,0.04013],[59,0.0064,17.3274,0.03977],
  [60,0.0058,17.4333,0.03943],
];

// ── POIDS filles (kg)
const List<List<double>> _whoPoidsFille = [
  [0,0.3809,3.2322,0.14171],[1,0.1714,4.1873,0.13724],[2,0.1714,5.1282,0.13000],
  [3,0.2986,5.8458,0.12619],[4,0.2986,6.4237,0.12214],[5,0.2986,6.8985,0.11898],
  [6,0.2986,7.2970,0.11634],[7,0.2986,7.6422,0.11418],[8,0.2986,7.9487,0.11232],
  [9,0.2986,8.2254,0.11065],[10,0.2986,8.4800,0.10911],[11,0.2986,8.7192,0.10764],
  [12,0.2986,8.9481,0.10622],[13,0.2986,9.1699,0.10478],[14,0.2986,9.3870,0.10340],
  [15,0.2986,9.6008,0.10208],[16,0.2986,9.8124,0.10083],[17,0.2986,10.0226,0.09963],
  [18,0.2986,10.2315,0.09850],[19,0.2986,10.4393,0.09741],[20,0.2986,10.6461,0.09636],
  [21,0.2986,10.8520,0.09534],[22,0.2986,11.0572,0.09434],[23,0.2986,11.2617,0.09337],
  [24,0.2986,11.4655,0.09243],[25,0.2986,11.6685,0.09152],[26,0.2986,11.8708,0.09063],
  [27,0.2986,12.0723,0.08977],[28,0.2986,12.2730,0.08893],[29,0.2986,12.4729,0.08811],
  [30,0.2986,12.6720,0.08731],[31,0.2986,12.8703,0.08654],[32,0.2986,13.0678,0.08578],
  [33,0.2986,13.2645,0.08504],[34,0.2986,13.4604,0.08432],[35,0.2986,13.6555,0.08361],
  [36,0.2986,13.8498,0.08292],[37,0.2986,14.0433,0.08224],[38,0.2986,14.2360,0.08158],
  [39,0.2986,14.4279,0.08094],[40,0.2986,14.6190,0.08030],[41,0.2986,14.8093,0.07968],
  [42,0.2986,14.9989,0.07908],[43,0.2986,15.1877,0.07849],[44,0.2986,15.3758,0.07791],
  [45,0.2986,15.5632,0.07735],[46,0.2986,15.7499,0.07680],[47,0.2986,15.9360,0.07626],
  [48,0.2986,16.1214,0.07573],[49,0.2986,16.3062,0.07521],[50,0.2986,16.4904,0.07471],
  [51,0.2986,16.6741,0.07421],[52,0.2986,16.8572,0.07373],[53,0.2986,17.0398,0.07326],
  [54,0.2986,17.2218,0.07280],[55,0.2986,17.4033,0.07235],[56,0.2986,17.5843,0.07191],
  [57,0.2986,17.7648,0.07148],[58,0.2986,17.9448,0.07106],[59,0.2986,18.1243,0.07065],
  [60,0.2986,18.3033,0.07025],
];

// ── TAILLE garçons (cm)
const List<List<double>> _whoTailleGarcon = [
  [0,1,49.8842,0.03795],[1,1,54.7244,0.03557],[2,1,58.4249,0.03424],
  [3,1,61.4292,0.03328],[4,1,63.8860,0.03257],[5,1,65.9026,0.03204],
  [6,1,67.6236,0.03165],[7,1,69.1645,0.03139],[8,1,70.5994,0.03124],
  [9,1,71.9687,0.03117],[10,1,73.2812,0.03118],[11,1,74.5388,0.03124],
  [12,1,75.7488,0.03132],[13,1,76.9186,0.03143],[14,1,78.0497,0.03155],
  [15,1,79.1458,0.03170],[16,1,80.2113,0.03185],[17,1,81.2467,0.03202],
  [18,1,82.2587,0.03220],[19,1,83.2418,0.03238],[20,1,84.1922,0.03257],
  [21,1,85.1201,0.03276],[22,1,86.0170,0.03296],[23,1,86.8876,0.03316],
  [24,1,87.8161,0.03306],[25,1,88.6884,0.03323],[26,1,89.5435,0.03340],
  [27,1,90.3741,0.03358],[28,1,91.1767,0.03376],[29,1,91.9523,0.03394],
  [30,1,92.7039,0.03412],[31,1,93.4309,0.03430],[32,1,94.1334,0.03448],
  [33,1,94.8133,0.03467],[34,1,95.4726,0.03485],[35,1,96.1116,0.03504],
  [36,1,96.7327,0.03522],[37,1,97.3354,0.03541],[38,1,97.9217,0.03559],
  [39,1,98.4928,0.03578],[40,1,99.0490,0.03597],[41,1,99.5907,0.03615],
  [42,1,100.1192,0.03634],[43,1,100.6348,0.03653],[44,1,101.1371,0.03671],
  [45,1,101.6263,0.03690],[46,1,102.1022,0.03709],[47,1,102.5663,0.03727],
  [48,1,103.0184,0.03746],[49,1,103.4590,0.03764],[50,1,103.8886,0.03783],
  [51,1,104.3077,0.03802],[52,1,104.7159,0.03820],[53,1,105.1143,0.03839],
  [54,1,105.5030,0.03857],[55,1,105.8826,0.03876],[56,1,106.2535,0.03894],
  [57,1,106.6154,0.03913],[58,1,106.9697,0.03931],[59,1,107.3162,0.03950],
  [60,1,107.6554,0.03968],
];

// ── TAILLE filles (cm)
const List<List<double>> _whoTailleFille = [
  [0,1,49.1477,0.03790],[1,1,53.6872,0.03640],[2,1,57.0673,0.03568],
  [3,1,59.8029,0.03520],[4,1,62.0899,0.03486],[5,1,64.0301,0.03463],
  [6,1,65.7311,0.03448],[7,1,67.2873,0.03441],[8,1,68.7498,0.03440],
  [9,1,70.1435,0.03444],[10,1,71.4818,0.03452],[11,1,72.7710,0.03463],
  [12,1,74.0150,0.03475],[13,1,75.2176,0.03490],[14,1,76.3817,0.03507],
  [15,1,77.5099,0.03524],[16,1,78.6055,0.03543],[17,1,79.6704,0.03562],
  [18,1,80.7079,0.03582],[19,1,81.7182,0.03602],[20,1,82.7020,0.03623],
  [21,1,83.6611,0.03644],[22,1,84.5968,0.03666],[23,1,85.5114,0.03688],
  [24,1,86.4153,0.03680],[25,1,87.3051,0.03700],[26,1,88.1810,0.03720],
  [27,1,89.0435,0.03739],[28,1,89.8931,0.03759],[29,1,90.7299,0.03779],
  [30,1,91.5541,0.03799],[31,1,92.3656,0.03818],[32,1,93.1645,0.03838],
  [33,1,93.9507,0.03858],[34,1,94.7243,0.03877],[35,1,95.4855,0.03897],
  [36,1,96.2344,0.03916],[37,1,96.9706,0.03936],[38,1,97.6946,0.03955],
  [39,1,98.4063,0.03975],[40,1,99.1058,0.03994],[41,1,99.7931,0.04013],
  [42,1,100.4684,0.04033],[43,1,101.1318,0.04052],[44,1,101.7834,0.04071],
  [45,1,102.4231,0.04090],[46,1,103.0514,0.04109],[47,1,103.6682,0.04128],
  [48,1,104.2736,0.04147],[49,1,104.8678,0.04166],[50,1,105.4511,0.04185],
  [51,1,106.0234,0.04204],[52,1,106.5851,0.04223],[53,1,107.1361,0.04242],
  [54,1,107.6770,0.04261],[55,1,108.2076,0.04279],[56,1,108.7283,0.04298],
  [57,1,109.2392,0.04317],[58,1,109.7405,0.04335],[59,1,110.2324,0.04354],
  [60,1,110.7151,0.04372],
];

// ── PÉRIMÈTRE CRÂNIEN garçons (cm)
const List<List<double>> _whoPcGarcon = [
  [0,1,34.4618,0.03686],[1,1,37.2759,0.03133],[2,1,39.1285,0.02997],
  [3,1,40.5135,0.02918],[4,1,41.6317,0.02861],[5,1,42.5858,0.02818],
  [6,1,43.3648,0.02785],[7,1,44.0191,0.02758],[8,1,44.5666,0.02737],
  [9,1,45.0243,0.02720],[10,1,45.4160,0.02706],[11,1,45.7585,0.02694],
  [12,1,46.0583,0.02685],[13,1,46.3208,0.02677],[14,1,46.5509,0.02671],
  [15,1,46.7534,0.02665],[16,1,46.9318,0.02661],[17,1,47.0889,0.02658],
  [18,1,47.2272,0.02656],[19,1,47.3486,0.02655],[20,1,47.4549,0.02655],
  [21,1,47.5476,0.02655],[22,1,47.6280,0.02656],[23,1,47.6975,0.02657],
  [24,1,47.7566,0.02659],[25,1,47.8080,0.02661],[26,1,47.8530,0.02664],
  [27,1,47.8937,0.02667],[28,1,47.9299,0.02671],[29,1,47.9622,0.02674],
  [30,1,47.9909,0.02678],[31,1,48.0163,0.02682],[32,1,48.0388,0.02686],
  [33,1,48.0586,0.02691],[34,1,48.0760,0.02695],[35,1,48.0912,0.02700],
  [36,1,48.1044,0.02705],[37,1,48.1159,0.02709],[38,1,48.1257,0.02714],
  [39,1,48.1341,0.02719],[40,1,48.1412,0.02724],[41,1,48.1472,0.02729],
  [42,1,48.1522,0.02734],[43,1,48.1563,0.02739],[44,1,48.1596,0.02745],
  [45,1,48.1622,0.02750],[46,1,48.1643,0.02755],[47,1,48.1659,0.02760],
  [48,1,48.1671,0.02766],[49,1,48.3330,0.02754],[50,1,48.3953,0.02758],
  [51,1,48.4544,0.02763],[52,1,48.5104,0.02767],[53,1,48.5635,0.02772],
  [54,1,48.6138,0.02776],[55,1,48.6615,0.02781],[56,1,48.7068,0.02785],
  [57,1,48.7499,0.02790],[58,1,48.7907,0.02794],[59,1,48.8295,0.02799],
  [60,1,48.8663,0.02803],
];

// ── PÉRIMÈTRE CRÂNIEN filles (cm)
const List<List<double>> _whoPcFille = [
  [0,1,33.8787,0.03496],[1,1,36.5463,0.03014],[2,1,38.2521,0.02878],
  [3,1,39.5328,0.02815],[4,1,40.5641,0.02763],[5,1,41.4508,0.02724],
  [6,1,42.1980,0.02694],[7,1,42.8217,0.02669],[8,1,43.3441,0.02650],
  [9,1,43.7871,0.02634],[10,1,44.1645,0.02621],[11,1,44.4884,0.02610],
  [12,1,44.7671,0.02601],[13,1,45.0070,0.02593],[14,1,45.2131,0.02587],
  [15,1,45.3893,0.02582],[16,1,45.5396,0.02578],[17,1,45.6671,0.02574],
  [18,1,45.7742,0.02572],[19,1,45.8632,0.02570],[20,1,45.9360,0.02569],
  [21,1,45.9943,0.02568],[22,1,46.0393,0.02568],[23,1,46.0725,0.02568],
  [24,1,46.0948,0.02569],[25,1,46.2051,0.02573],[26,1,46.2613,0.02575],
  [27,1,46.3142,0.02578],[28,1,46.3641,0.02580],[29,1,46.4112,0.02583],
  [30,1,46.4555,0.02586],[31,1,46.4973,0.02588],[32,1,46.5366,0.02591],
  [33,1,46.5737,0.02594],[34,1,46.6086,0.02597],[35,1,46.6414,0.02600],
  [36,1,46.6722,0.02603],[37,1,46.7012,0.02606],[38,1,46.7285,0.02609],
  [39,1,46.7541,0.02612],[40,1,46.7783,0.02615],[41,1,46.8010,0.02618],
  [42,1,46.8224,0.02621],[43,1,46.8426,0.02624],[44,1,46.8617,0.02627],
  [45,1,46.8797,0.02630],[46,1,46.8967,0.02633],[47,1,46.9129,0.02636],
  [48,1,46.9282,0.02639],[49,1,47.0765,0.02632],[50,1,47.1222,0.02635],
  [51,1,47.1660,0.02638],[52,1,47.2083,0.02641],[53,1,47.2489,0.02644],
  [54,1,47.2882,0.02647],[55,1,47.3261,0.02650],[56,1,47.3628,0.02653],
  [57,1,47.3983,0.02656],[58,1,47.4327,0.02659],[59,1,47.4660,0.02662],
  [60,1,47.4984,0.02665],
];


// INTERPOLATION LMS — Z-score OMS


List<double> _interpolateLMS(List<List<double>> table, double months) {
  months = months.clamp(0, 60);
  int lo = months.floor().clamp(0, table.length - 2);
  int hi = (lo + 1).clamp(0, table.length - 1);
  double t = months - lo;

  double L = table[lo][1] + t * (table[hi][1] - table[lo][1]);
  double M = table[lo][2] + t * (table[hi][2] - table[lo][2]);
  double S = table[lo][3] + t * (table[hi][3] - table[lo][3]);
  return [L, M, S];
}

double _calcZScore(double value, double L, double M, double S) {
  if (L.abs() < 1e-6) return log(value / M) / S;
  return (pow(value / M, L) - 1) / (L * S);
}


// IMC : tables LMS OMS

const List<List<double>> _whoImcGarcon = [
  [0,1,13.4069,0.09546],[3,1,15.3647,0.08181],[6,1,16.4920,0.07915],
  [9,1,16.4854,0.07969],[12,1,16.1075,0.08186],[18,1,15.3739,0.08517],
  [24,1,15.1657,0.08705],[30,1,15.1027,0.08929],[36,1,15.1088,0.09058],
  [42,1,15.1586,0.09180],[48,1,15.2258,0.09294],[54,1,15.3000,0.09395],
  [60,1,15.3764,0.09477],
];

const List<List<double>> _whoImcFille = [
  [0,1,13.3363,0.09519],[3,1,15.0611,0.08104],[6,1,16.0500,0.07948],
  [9,1,15.9459,0.08026],[12,1,15.5579,0.08276],[18,1,14.8823,0.08649],
  [24,1,14.7486,0.08808],[30,1,14.7226,0.08999],[36,1,14.7474,0.09097],
  [42,1,14.8051,0.09197],[48,1,14.8775,0.09296],[54,1,14.9591,0.09388],
  [60,1,15.0427,0.09468],
];

List<double> _interpolateImcLMS(List<List<double>> table, double months) {
  months = months.clamp(0, 60);
  // Trouve les deux entrées encadrantes
  int hi = 1;
  while (hi < table.length - 1 && table[hi][0] < months) hi++;
  int lo = hi - 1;
  double range = table[hi][0] - table[lo][0];
  double t = range == 0 ? 0 : (months - table[lo][0]) / range;
  double L = table[lo][1] + t * (table[hi][1] - table[lo][1]);
  double M = table[lo][2] + t * (table[hi][2] - table[lo][2]);
  double S = table[lo][3] + t * (table[hi][3] - table[lo][3]);
  return [L, M, S];
}


// DIAGNOSTIC MÉDICAL PRINCIPAL


class _WhoResult {
  final double zScore;
  final double percentile;
  final int status;       // 0=Normal 1=Alerte 2=Critique
  final String label;
  _WhoResult({required this.zScore, required this.percentile, required this.status, required this.label});
}

_WhoResult _whoZScoreResult(double value, double L, double M, double S, String type) {
  double z = _calcZScore(value, L, M, S).clamp(-6.0, 6.0);
  double pct = _zScoreToPercentile(z);

  int status = 0;
  String label = "NORMAL";

  // Seuils OMS
  if (type == "IMC") {
    if (z > 3)       { label = "OBÉSITÉ";       status = 2; }
    else if (z > 2)  { label = "SURPOIDS";       status = 1; }
    else if (z < -3) { label = "ÉMACIATION SÉV"; status = 2; }
    else if (z < -2) { label = "ÉMACIÉ";         status = 1; }
  } else if (type == "Poids") {
    if (z > 3)       { label = "TRÈS ÉLEVÉ";     status = 2; }
    else if (z > 2)  { label = "ÉLEVÉ";          status = 1; }
    else if (z < -3) { label = "MALNUTRITION SÉV"; status = 2; }
    else if (z < -2) { label = "INSUFFISANT";    status = 1; }
  } else if (type == "Taille") {
    if (z > 3)       { label = "TRÈS GRAND";     status = 2; }
    else if (z > 2)  { label = "GRAND";          status = 1; }
    else if (z < -3) { label = "RETARD SÉV";     status = 2; }
    else if (z < -2) { label = "RETARD CROISS."; status = 1; }
  } else { // PC
    if (z > 3)       { label = "MACROCÉPHALIE";  status = 2; }
    else if (z > 2)  { label = "PC ÉLEVÉ";       status = 1; }
    else if (z < -3) { label = "MICROCÉPH. SÉV"; status = 2; }
    else if (z < -2) { label = "MICROCÉPHALIE";  status = 1; }
  }

  return _WhoResult(zScore: z, percentile: pct, status: status, label: label);
}


Map<String, dynamic> _getMedicalDiagnostic(
    String type, double value, int ageInDays, String sexe) {

  if (value <= 0) {
    return {"status": 0, "label": "—", "percentile": 50.0, "zScore": 0.0};
  }

  bool isBoy = sexe.toLowerCase().contains("masc") ||
      sexe.toLowerCase().contains("gar");
  double months = (ageInDays / 30.4375).clamp(0, 60);

  List<double> lms;
  String cat;

  switch (type) {
    case "Poids":
      lms = _interpolateLMS(isBoy ? _whoPoidsGarcon : _whoPoidsFille, months);
      cat = "Poids";
      break;
    case "Taille":
      lms = _interpolateLMS(isBoy ? _whoTailleGarcon : _whoTailleFille, months);
      cat = "Taille";
      break;
    case "PC":
      lms = _interpolateLMS(isBoy ? _whoPcGarcon : _whoPcFille, months);
      cat = "PC";
      break;
    default: // IMC
      lms = _interpolateImcLMS(isBoy ? _whoImcGarcon : _whoImcFille, months);
      cat = "IMC";
  }

  final r = _whoZScoreResult(value, lms[0], lms[1], lms[2], cat);
  return {
    "status": r.status,
    "label": r.label,
    "percentile": r.percentile,
    "zScore": r.zScore,
  };
}


// STATISTIQUES


double _zScoreToPercentile(double z) =>
    (0.5 * (1 + _erf(z / sqrt(2)))) * 100;

double _erf(double x) {
  double t = 1.0 / (1.0 + 0.5 * x.abs());
  double ans = 1 -
      t *
          exp(-x * x -
              1.26551223 +
              t * (1.00002368 +
                  t * (0.37409196 +
                      t * (0.09678418 +
                          t * (-0.18628806 +
                              t * (0.27886807 +
                                  t * (-1.13520398 +
                                      t * (1.48851587 +
                                          t * (-0.82215223 +
                                              t * 0.17087277)))))))));
  return x >= 0 ? ans : -ans;
}
Map<String, String> _toParentMessage(String type, int status, String label, double percentile) {
  // ── Textes par indicateur + statut ──────────────────────────────
  const messages = <String, Map<int, Map<String, String>>>{
    "Poids": {
      0: {"emoji": "✅", "title": "Poids normal", "advice": "Continuez comme ça ! L'alimentation de votre bébé est bien adaptée à son âge."},
      1: {
        "emoji": "⚠️",
        "title": "Poids à surveiller",
        "advice": "Le poids de votre bébé s'écarte un peu de la normale. Parlez-en à votre médecin lors du prochain rendez-vous.",
      },
      2: {"emoji": "🔴", "title": "Poids préoccupant", "advice": "Nous vous recommandons de consulter votre pédiatre rapidement pour un bilan nutritionnel."},
    },
    "Taille": {
      0: {"emoji": "✅", "title": "Taille normale", "advice": "Votre bébé grandit bien par rapport aux enfants de son âge."},
      1: {"emoji": "⚠️", "title": "Taille à surveiller", "advice": "La taille de votre bébé s'éloigne un peu de la moyenne. Mentionnez-le à votre médecin."},
      2: {"emoji": "🔴", "title": "Taille préoccupante", "advice": "Il est conseillé de consulter rapidement votre pédiatre pour évaluer la croissance."},
    },
    "PC": {
      0: {"emoji": "✅", "title": "Tour de tête normal", "advice": "Le tour de tête de votre bébé se développe bien."},
      1: {"emoji": "⚠️", "title": "Tour de tête à surveiller", "advice": "La mesure du tour de tête sort légèrement de la normale. Signalez-le à votre médecin."},
      2: {"emoji": "🔴", "title": "Tour de tête préoccupant", "advice": "Consultez votre pédiatre prochainement pour un contrôle du développement cérébral."},
    },
    "IMC": {
      0: {"emoji": "✅", "title": "Corpulence normale", "advice": "La corpulence de votre bébé est bien équilibrée pour son âge."},
      1: {"emoji": "⚠️", "title": "Corpulence à surveiller", "advice": "La corpulence de votre bébé commence à s'éloigner de la normale. Votre médecin pourra vous conseiller."},
      2: {"emoji": "🔴", "title": "Corpulence préoccupante", "advice": "Consultez votre pédiatre pour un bilan et des conseils alimentaires adaptés."},
    },
  };

  final m = messages[type]?[status] ?? {"emoji": "✅", "title": "Normal", "advice": ""};
  return {
    "emoji":   m["emoji"]!,
    "title":   m["title"]!,
    "advice":  m["advice"]!,
  };
}

/// Label de position
String _percentileToParentText(double pct) {
  if (pct < 3)  return "En dessous de la plupart des bébés";
  if (pct < 15) return "Un peu en dessous de la moyenne";
  if (pct < 85) return "Dans la moyenne";
  if (pct < 97) return "Un peu au-dessus de la moyenne";
  return "Au-dessus de la plupart des bébés";
}


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