import 'package:flutter/material.dart';

class HealthArticle {
  final String id, category;
  final String titleFr, titleAr;
  final String summaryFr, summaryAr;
  final String contentFr, contentAr;
  final List<String> images;
  final int readTime;

  HealthArticle({
    required this.id, required this.category,
    required this.titleFr, required this.titleAr,
    required this.summaryFr, required this.summaryAr,
    required this.contentFr, required this.contentAr,
    required this.images, required this.readTime,
  });
}

// ---------------------------------------------------------------------
// BASE DE DONNÉES COMPLÈTE
// ---------------------------------------------------------------------
final List<HealthArticle> allArticles = [
  HealthArticle(
    id: "1", category: "Vaccination",
    titleFr: "Vaccination dT", titleAr: "تلقيح dT",
    summaryFr: "Protégez maman et bébé", summaryAr: "حماية الأم والطفل",
    contentFr: "La vaccination contre la diphtérie et le tétanos (dT) est essentielle pour la santé de la future maman et pour protéger le nouveau-né avant qu'il ne puisse être vacciné.\n\nPourquoi se faire vacciner ? Elle permet de transmettre des anticorps protecteurs au bébé pour les premiers mois de sa vie.\n\nQuand se faire vacciner ? Le moment de la vaccination dépend de vos antécédents. En général, si votre dernière dose remonte à plus de 10 ans, une injection est recommandée dès la 14ème semaine d'aménorrhée (SA).",
    contentAr: "يعد التطعيم ضد الخناق والكزاز أمراً ضرورياً لصحة الأم الحامل ولحماية المولود الجديد قبل أن يتمكن من تلقي لقاحاته الخاصة.\n\nلماذا يجب التطعيم؟ لأنه يسمح بنقل الأجسام المضادة الواقية إلى الطفل لحمايته في الأشهر الأولى من حياته.\n\nمتى يجب التطعيم؟ يعتمد توقيت التطعيم على تاريخك الطبي. بشكل عام، إذا مرت أكثر من 10 سنوات على آخر جرعة، يوصى بحقنة واحدة بدءاً من الأسبوع الـ 14 من الحمل.",
    images: ["assets/vacc.png"], readTime: 4,
  ),
  HealthArticle(
    id: "2", category: "Grossesse",
    titleFr: "Grossesse saine", titleAr: "حمل صحي",
    summaryFr: "Conseils essentiels", summaryAr: "نصائح مهمة",
    contentFr: "Alimentation saine : Adoptez un régime varié.\n\nVitamine D : Une dose unique de 100 000 UI est conseillée à la 32ème semaine.\n\nContrôlez les sucres : Limitez les aliments sucrés.\n\nHygiène dentaire : Brossez-vous les dents deux fois par jour.\n\nPréparation : Pensez déjà à vous préparer pour l'allaitement maternel.",
    contentAr: "نظام غذائي صحي: اتبعي نظاماً غذائياً متنوعاً.\n\nفيتامين د: يُنصح بجرعة واحدة في الأسبوع الـ 32 لتقوية العظام.\n\nالتحكم في السكريات: قللي من الأطعمة السكرية.\n\nنظافة الأسنان: اغسلي أسنانك مرتين يومياً.\n\nالاستعداد: فكري بالفعل في الاستعداد للرضاعة الطبيعية.",
    images: ["assets/enc.png"], readTime: 5,
  ),
  HealthArticle(
    id: "3", category: "Allaitement",
    titleFr: "L'Allaitement Maternel", titleAr: "الرضاعة الطبيعية",
    summaryFr: "Le meilleur aliment", summaryAr: "أفضل بداية لطفلك",
    contentFr: "Le lait maternel est l'aliment le plus complet pour votre enfant durant ses 6 premiers mois.\n\nÀ la demande : Donnez le sein aussi souvent que votre bébé le demande.\n\nDifficultés : En cas de douleurs, crevasses ou impression de manque de lait, ne vous découragez pas. Demandez conseil à votre médecin.",
    contentAr: "حليب الأم هو الغذاء الأكثر اكتمالاً لطفلك خلال الأشهر الستة الأولى من حياته.\n\nعند الطلب: قومي بإرضاع طفلك كلما طلب ذلك. هذا يساعد في زيادة إنتاج الحليب.\n\nالصعوبات: في حالة وجود آلام أو تشققات أو شعور بنقص الحليب، لا تستسلمي. اطلبي النصيحة من طبيبك.",
    images: ["assets/alai.png"], readTime: 6,
  ),
  HealthArticle(
    id: "4", category: "Hygiène",
    titleFr: "Le Bain du Nouveau-né", titleAr: "حمام الطفل",
    summaryFr: "Moment de détente", summaryAr: "لحظة استرخاء بأمان",
    contentFr: "Température de l'eau : L'eau doit être à 37 °C. Vérifiez-la avec un thermomètre.\n\nLe bain : Maintenez fermement votre bébé et introduisez-le progressivement.\n\nDurée : Le bain doit être court, pas plus de 5-10 minutes.\n\nAprès le bain : Séchez votre bébé délicatement.",
    contentAr: "درجة حرارة الماء: يجب أن تكون 37 درجة مئوية.\n\nالحمام: امسكي طفلك بإحكام وأدخليه تدريجياً إلى الماء.\n\nالمدة: يجب أن يكون الحمام قصيراً، لا يزيد عن 5-10 دقائق.\n\nبعد الحمام: جففي طفلك بلطف وبسرعة.",
    images: ["assets/bain.png"], readTime: 3,
  ),
  HealthArticle(
    id: "5", category: "Sommeil",
    titleFr: "Le Sommeil", titleAr: "نوم الطفل",
    summaryFr: "Dormir en sécurité", summaryAr: "نوم آمن لأحلام سعيدة",
    contentFr: "Température de la chambre : Entre 18 °C et 20 °C.\n\nSur le dos : Faites dormir votre bébé sur le dos, à plat.\n\nLit vide : Utilisez un matelas ferme. Pas d'oreiller, de couette ou de doudous (risque d'étouffement).\n\nPas de médicaments : Ne donnez jamais de médicaments pour dormir.",
    contentAr: "درجة حرارة الغرفة: بين 18 و 20 درجة مئوية.\n\nعلى الظهر: اجعلي طفلك ينام على ظهره منذ الولادة.\n\nسرير فارغ: استخدمي مرتبة صلبة. لا تستخدمي وسادة أو لحاف في السرير.\n\nلا أدوية: لا تعطي طفلك أبداً أدوية لمساعدته على النوم.",
    images: ["assets/somail.png"], readTime: 4,
  ),
  HealthArticle(
    id: "6", category: "Développement",
    titleFr: "Développement 1-3 mois", titleAr: "تطور 1-3 أشهر",
    summaryFr: "Premiers exploits", summaryAr: "إنجازات طفلك الأولى",
    contentFr: "1 mois : Serre le doigt, fixe le regard.\n\n2 mois : Sourit en réponse à un sourire, émet des vocalises ('aa', 'eu').\n\n3 mois : Tient la tête droite en position assise, tourne la tête pour suivre un objet.",
    contentAr: "حول الشهر الأول: يتمسك بالإصبع، يُثبت نظره على من يحدثه.\n\nحول الشهر الثاني: يبتسم استجابةً لابتسامة، يصدر نغمات صوتية.\n\nحول الشهر الثالث: يمسك رأسه مستقيماً، يدير رأسه لمتابعة الأشياء.",
    images: ["assets/dev.png"], readTime: 5,
  ),
  HealthArticle(
    id: "7", category: "Développement",
    titleFr: "Développement 4-6 mois", titleAr: "تطور 4-6 أشهر",
    summaryFr: "Nouvelles découvertes", summaryAr: "اكتشافات جديدة",
    contentFr: "4 mois : Maintient le tronc droit un court moment, tourne la tête à l'appel.\n\n5 mois : Saisit un objet au contact de la main.\n\n6 mois : Se retourne du dos sur le ventre, prend ses pieds dans ses mains.",
    contentAr: "حول الشهر الرابع: يحافظ على جذعه مستقيماً، يدير رأسه عند النداء.\n\nحول الشهر الخامس: يمسك شيئاً عند ملامسته ليده.\n\nحول الشهر السادس: يتقلب من ظهره على بطنه، يمسك قدميه في يديه.",
    images: ["assets/dev1.png"], readTime: 5,
  ),
  HealthArticle(
    id: "8", category: "Digestif",
    titleFr: "Les Selles de Bébé", titleAr: "براز الطفل",
    summaryFr: "Guide visuel quotidien", summaryAr: "دليل مرئي للبراز",
    contentFr: "Selles jaunes d'or : Idéal pour un bébé nourri au sein.\n\nSelles brun-jaune / vert-olive : Typique pour un bébé au biberon.\n\nEn général : Tant que les selles sont jaunes, brunes ou vertes et que bébé est en forme, tout va bien.",
    contentAr: "براز ذهبي أصفر: اللون المثالي للرضاعة الطبيعية.\n\nبراز بني أصفر: اللون النموذجي للرضاعة الصناعية.\n\nبشكل عام: طالما أن البراز أصفر أو بني أو أخضر وطفلك بخير، فكل شيء طبيعي.",
    images: ["assets/diarre.png"], readTime: 2,
  ),
  HealthArticle(
    id: "9", category: "Urgence",
    titleFr: "Diarrhée et Signes", titleAr: "الإسهال والجفاف",
    summaryFr: "Quand consulter en urgence", summaryAr: "علامات الخطر والجفاف",
    contentFr: "Consultez en urgence si :\n- Fièvre, vomissements ou refus d'alimentation.\n- Sécheresse de la bouche / somnolence.\n- Fontanelle déprimée (creuse).\n- Moins de 4 couches mouillées par jour.",
    contentAr: "علامات تستوجب الطبيب فوراً:\n- حمى، قيء أو رفض الأكل.\n- جفاف الفم أو النعاس.\n- يافوخ منخفض (مجوف).\n- أقل من 4 حفاضات مبللة في اليوم.",
    images: ["assets/diarre1.png"], readTime: 4,
  ),
  HealthArticle(
    id: "10", category: "Hygiène",
    titleFr: "Dents", titleAr: "الأسنان",
    summaryFr: "Brossage et soin", summaryAr: "تنظيف الأسنان",
    contentFr: "Dès 15 mois : La maman doit brosser les dents de bébé.\n\nÀ partir de 3 ans : L'enfant doit se brosser les dents seul.\n\nFréquence : Après chaque repas pendant 3 minutes.",
    contentAr: "اعتباراً من الشهر الـ 15: تقوم الأم بتنظيف أسنان الرضيع.\n\nاعتباراً من الـ 3 سنوات: ينظف الطفل أسنانه لوحده.\n\nالواتيرة: بعد كل وجبة لمدة 3 دقائق.",
    images: ["assets/dent.png"], readTime: 2,
  ),
  HealthArticle(
    id: "11", category: "Nutrition",
    titleFr: "Vitamine D", titleAr: "فيتامين د",
    summaryFr: "Pour des os solides", summaryAr: "عظام قوية",
    contentFr: "Exposition au soleil : 15 minutes, trois fois par semaine.\n\nAlimentation : Œufs, poisson gras, produits laitiers.\n\nSupplémentation : Une ampoule de vitamine D3 est souvent nécessaire selon l'avis médical.",
    contentAr: "التعرض للشمس: 15 دقيقة، ثلاث مرات في الأسبوع.\n\nنظام غذائي: البيض، الأسماك الدهنية، منتجات الألبان.\n\nالمكملات: غالباً ما يحتاج الطفل أمبولة فيتامين د3 حسب استشارة الطبيب.",
    images: ["assets/vitamin.png"], readTime: 3,
  ),
  HealthArticle(
    id: "12", category: "Nutrition",
    titleFr: "Alimentation 0-12 mois", titleAr: "التغذية 0-12 شهر",
    summaryFr: "Repères nutritionnels", summaryAr: "دليل التغذية حسب العمر",
    contentFr: "0 à 6 mois : Allaitement maternel exclusif.\n\n6 à 10 mois : Diversification (texture mixée). Légumes + viande/poisson.\n\n10 à 12 mois : Texture moulinée à hachée. Augmentation des quantités.",
    contentAr: "من 0 إلى 6 أشهر: رضاعة طبيعية حصرية.\n\nمن 6 إلى 10 أشهر: التنويع (قوام مخلوط). خضروات + لحم.\n\nمن 10 إلى 12 شهراً: قوام مطحون إلى مفروم وزيادة الكميات.",
    images: ["assets/nutrition.png"], readTime: 4,
  ),
  HealthArticle(
    id: "13", category: "Protection",
    titleFr: "Protection Solaire", titleAr: "حماية من الشمس",
    summaryFr: "Peau fragile", summaryAr: "حماية الطفل من الشمس",
    contentFr: "Évitez l'exposition directe jusqu'à 1 an. Utilisez un chapeau, des lunettes et des vêtements légers.\n\nLe soleil est dangereux pour la peau fragile des nourrissons.",
    contentAr: "تجنب تعريض الطفل لأشعة الشمس المباشرة حتى عمر سنة واحدة. استخدم قبعة ونظارات وملابس خفيفة لحماية الجلد.",
    images: ["assets/solaire.png"], readTime: 2,
  ),
];

class EducationalArticlesScreen extends StatefulWidget {
  @override
  _EducationalArticlesScreenState createState() => _EducationalArticlesScreenState();
}

class _EducationalArticlesScreenState extends State<EducationalArticlesScreen> {
  String query = "";
  String selectedCat = "Tous";
  bool isFr = true;

  final List<String> categories = ["Tous", "Vaccination", "Grossesse", "Nutrition", "Hygiène", "Sommeil", "Développement", "Urgence"];

  @override
  Widget build(BuildContext context) {
    final filtered = allArticles.where((a) {
      final matchesSearch = (isFr ? a.titleFr : a.titleAr).toLowerCase().contains(query.toLowerCase());
      final matchesCat = selectedCat == "Tous" || a.category == selectedCat;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120, floating: true, pinned: true,
            backgroundColor: Colors.white, elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(isFr ? "Guide Santé" : "دليل الصحة",
                  style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(backgroundColor: Colors.blue[50],
                    child: Text(isFr ? "AR" : "FR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue))),
                onPressed: () => setState(() => isFr = !isFr),
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: InputDecoration(
                      hintText: isFr ? "Rechercher un conseil..." : "بحث عن موضوع...",
                      prefixIcon: Icon(Icons.search, color: Colors.blue),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      bool isSelected = selectedCat == categories[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ChoiceChip(
                          label: Text(categories[i]),
                          selected: isSelected,
                          onSelected: (val) => setState(() => selectedCat = categories[i]),
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.blue[900]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final a = filtered[i];
                  return Container(
                    margin: EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(art: a, isFr: isFr))),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.horizontal(left: isFr ? Radius.circular(20) : Radius.zero, right: isFr ? Radius.zero : Radius.circular(20)),
                            child: Image.asset(a.images.first, width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.image, size: 50)),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: isFr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                children: [
                                  Text(a.category, style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text(isFr ? a.titleFr : a.titleAr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(isFr ? a.summaryFr : a.summaryAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class DetailScreen extends StatelessWidget {
  final HealthArticle art;
  final bool isFr;
  DetailScreen({required this.art, required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(art.images.first, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.image, size: 100)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: isFr ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                        child: Text(art.category, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                      Text("${art.readTime} min read", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(isFr ? art.titleFr : art.titleAr,
                      textAlign: isFr ? TextAlign.left : TextAlign.right,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                  SizedBox(height: 20),
                  Text(isFr ? art.contentFr : art.contentAr,
                      textAlign: isFr ? TextAlign.justify : TextAlign.right,
                      textDirection: isFr ? TextDirection.ltr : TextDirection.rtl,
                      style: TextStyle(fontSize: 17, height: 1.6, color: Colors.black87)),
                  SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            isFr ? "Note : Consultez toujours un médecin en cas de doute." : "ملاحظة: استشيري دائماً الطبيب في حال وجود شك.",
                            style: TextStyle(color: Colors.red[900], fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}