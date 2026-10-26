import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login.dart';

class OnboardingVideoPage extends StatefulWidget {
  const OnboardingVideoPage({super.key});

  @override
  State<OnboardingVideoPage> createState() => _OnboardingVideoPageState();
}

class _OnboardingVideoPageState extends State<OnboardingVideoPage> {
  late PageController _pageController;
  int _currentPage = 0;
  VideoPlayerController? _videoController;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Bienvenue dans la famille",
      "subtitle": "VOTRE ALLIÉ AU QUOTIDIEN",
      "description": "TifliCare digitalise le carnet de santé de votre trésor. La santé de votre bébé, protégée et toujours à portée de main.",
      "video": "assets/step0.mp4",
    },
    {
      "title": "Un suivi intelligent",
      "subtitle": "VIGILANCE SANTÉ",
      "description": "Ajoutez les mesures de votre enfant en un geste. En cas d'anomalie, TifliCare vous alerte immédiatement pour agir vite.",
      "video": "assets/step1.mp4",
    },
    {
      "title": "Le plein de vitalité",
      "subtitle": "GUIDE NUTRITIONNEL",
      "description": "Réussissez l'étape de la diversification. Découvrez les conseils officiels pour des repas sains et adaptés à son âge.",
      "video": "assets/step3.mp4",
    },
    {
      "title": "Sa protection, notre priorité",
      "subtitle": "ZÉRO OUBLI",
      "description": "Vaccins, Visites .. Recevez des rappels automatiques pour ne manquer aucune étape clé de sa protection.",
      "video": "assets/step4.mp4",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // VERIFICATION PLATEFORME : Si Web ou écran large (PC), on saute l'onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb || MediaQuery.of(context).size.width > 600) {
        _finishOnboarding();
      } else {
        _initVideo(_currentPage);
      }
    });
  }

  void _initVideo(int index) async {
    final oldController = _videoController;
    final controller = VideoPlayerController.asset(_onboardingData[index]['video']!);
    _videoController = controller;

    if (oldController != null) {
      await oldController.pause();
      oldController.dispose();
    }

    await controller.initialize();
    controller.setLooping(true);
    controller.setVolume(0);
    controller.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || MediaQuery.of(context).size.width > 600) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              flex: 4,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  _initVideo(index);
                  setState(() => _currentPage = index);
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => _buildText(index),
              ),
            ),


            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    color: Colors.black,
                    child: _videoController != null && _videoController!.value.isInitialized
                        ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                        : const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              ),
            ),


            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildText(int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
      child: Column(
        children: [
          Text(
            _onboardingData[index]['subtitle']!,
            style: const TextStyle(
              color: Color(0xFF2196F3),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _onboardingData[index]['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            _onboardingData[index]['description']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    bool isLast = _currentPage == _onboardingData.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _onboardingData.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                height: 6,
                width: _currentPage == i ? 24 : 6,
                decoration: BoxDecoration(
                  color: _currentPage == i ? const Color(0xFF1A237E) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: isLast ? _finishOnboarding : () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: Text(
              isLast ? "C'EST PARTI !" : "SUIVANT",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage())
      );
    }
  }
}