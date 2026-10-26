import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatbot interface.dart'; // contient AIService (renomme en chatbot_interface.dart si possible)
import 'chat_history.dart';

class ChatScreen extends StatefulWidget {
  final String babyId;
  final Map<String, dynamic>? babyData;
  final String? chatId; // pour rouvrir une conversation existante
  const ChatScreen({
    Key? key,
    required this.babyId,
    this.babyData,
    this.chatId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _teal = Color(0xFF318785);
  static const Color _blue = Color(0xFF2196F3);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String? _chatId;
  String _extraContext = '';

  CollectionReference<Map<String, dynamic>> get _chats => FirebaseFirestore
      .instance
      .collection('babies')
      .doc(widget.babyId)
      .collection('chats');

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    // Charge mesures, visites et repas du jour pour personnaliser l'IA
    AIService.loadBabyContext(widget.babyId).then((c) => _extraContext = c);
    if (_chatId != null) _loadChat(_chatId!);
  }

  Future<void> _loadChat(String id) async {
    try {
      final doc = await _chats.doc(id).get();
      final list = (doc.data()?['messages'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _chatId = id;
        _messages
          ..clear()
          ..addAll(list.map((m) => <String, String>{
            "role": (m['role'] ?? 'user').toString(),
            "text": (m['text'] ?? '').toString(),
          }));
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Chargement conversation impossible : $e");
    }
  }

  Future<void> _saveChat() async {
    try {
      final first = _messages.firstWhere(
            (m) => m['role'] == 'user',
        orElse: () => {'text': 'Conversation'},
      )['text']!;
      final title = first.length > 45 ? '${first.substring(0, 45)}…' : first;

      if (_chatId == null) {
        final ref = await _chats.add({
          'title': title,
          'messages': _messages,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _chatId = ref.id;
      } else {
        await _chats.doc(_chatId).set({
          'title': title,
          'messages': _messages,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Le chat continue de fonctionner même si la sauvegarde échoue
      debugPrint("Sauvegarde conversation impossible : $e");
    }
  }

  Future<void> _openHistory() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatHistoryScreen(
          babyId: widget.babyId,
          babyName: _babyName,
          currentChatId: _chatId,
        ),
      ),
    );
    if (result == null) return;
    if (result.isEmpty) {
      setState(() {
        _messages.clear();
        _chatId = null;
      });
    } else {
      _loadChat(result);
    }
  }

  String get _babyName =>
      widget.babyData?['prenom'] ?? widget.babyData?['nom'] ?? "votre bébé";

  // Âge calculé depuis la date de naissance
  String _ageText() {
    try {
      final raw = widget.babyData?['dateNaissance'];
      if (raw == null) return "";
      final DateTime birth = raw is Timestamp
          ? raw.toDate()
          : DateTime.parse(raw.toString().replaceAll('/', '-'));
      final now = DateTime.now();
      int years = now.year - birth.year;
      int months = now.month - birth.month;
      int days = now.day - birth.day;
      if (days < 0) {
        months--;
        days += 30;
      }
      if (months < 0) {
        years--;
        months += 12;
      }
      if (years > 0) return "$years an${years > 1 ? 's' : ''}";
      if (months > 0) return "$months mois";
      return "$days jours";
    } catch (_) {
      return "";
    }
  }

  List<String> get _suggestions => [
    "Que dois-je donner à manger à mon bébé ?",
    "Quels vaccins sont prévus bientôt ?",
    "Est-ce que son poids est normal ?",
    "Comment améliorer son sommeil ?",
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final aiResponse = await AIService.sendMessage(
      _messages,
      babyData: widget.babyData,
      extraContext: _extraContext,
    );

    if (!mounted) return;
    setState(() {
      _messages.add({"role": "assistant", "text": aiResponse});
      _isLoading = false;
    });
    _scrollToBottom();
    _saveChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _messages.isEmpty ? _buildWelcome() : _buildMessages(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ---------- En-tête dégradé ----------
  Widget _buildHeader(BuildContext context) {
    final age = _ageText();
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_teal, _blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x334CB8C4), blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration:
            const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy_rounded, color: _teal, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Assistant TifliCare",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFF69F0AE), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        age.isEmpty
                            ? "En ligne"
                            : "En ligne • $_babyName, $age",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: "Nouvelle conversation",
              icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
              onPressed: () => setState(() {
                _messages.clear();
                _chatId = null;
              }),
            ),
          IconButton(
            tooltip: "Historique",
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: _openHistory,
          ),
        ],
      ),
    );
  }

  // ---------- Écran d'accueil ----------
  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _teal.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: _teal, size: 30),
                ),
                const SizedBox(height: 14),
                Text("Bonjour ! Parlons de $_babyName",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142))),
                const SizedBox(height: 8),
                Text(
                  "Je peux vous aider pour l'alimentation, la croissance et le calendrier vaccinal, selon les recommandations de l'OMS.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("SUGGESTIONS",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(height: 10),
          ..._suggestions.map(
                (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _sendMessage(s),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _blue.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(s,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500))),
                      const Icon(Icons.arrow_forward_ios,
                          size: 13, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Cet assistant ne remplace pas un médecin. En cas d'urgence, consultez un pédiatre ou rendez-vous aux urgences.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ---------- Liste des messages ----------
  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTyping();
        final msg = _messages[index];
        return _buildBubble(msg["text"] ?? "", msg["role"] == "user");
      },
    );
  }

  Widget _botAvatar() => Container(
    margin: const EdgeInsets.only(right: 8, bottom: 2),
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
        color: _teal.withOpacity(0.12), shape: BoxShape.circle),
    child: const Icon(Icons.smart_toy_rounded, size: 16, color: _teal),
  );

  Widget _buildBubble(String text, bool isUser) {
    final maxW = MediaQuery.of(context).size.width * 0.75;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _botAvatar(),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(colors: [_teal, _blue])
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: SelectableText(
                text,
                style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF2D3142),
                    fontSize: 14,
                    height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ---------- Barre de saisie ----------
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Posez votre question sur $_babyName...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isLoading ? 0.5 : 1,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_teal, _blue]),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Animation "est en train d'écrire" ----------
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_c.value - i * 0.2) % 1.0);
            final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8 * scale + 2,
              height: 8 * scale + 2,
              decoration: BoxDecoration(
                color: const Color(0xFF318785).withOpacity(0.4 + 0.6 * scale / 1.0 * 0.6),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}