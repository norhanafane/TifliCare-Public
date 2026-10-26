import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Liste des anciennes conversations d'un bébé.
/// Retourne (via Navigator.pop) :
///  - l'id d'une conversation pour l'ouvrir
///  - '' pour démarrer une nouvelle conversation
///  - null si l'utilisateur revient simplement en arrière
class ChatHistoryScreen extends StatelessWidget {
  final String babyId;
  final String babyName;
  final String? currentChatId;

  const ChatHistoryScreen({
    super.key,
    required this.babyId,
    required this.babyName,
    this.currentChatId,
  });

  static const Color _teal = Color(0xFF318785);
  static const Color _blue = Color(0xFF2196F3);

  CollectionReference<Map<String, dynamic>> get _chats => FirebaseFirestore
      .instance
      .collection('babies')
      .doc(babyId)
      .collection('chats');

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Supprimer cette conversation ?"),
        content: const Text("Cette action est définitive."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Annuler")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Supprimer",
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    return ok ?? false;
  }

  String _dateText(dynamic ts) {
    if (ts is! Timestamp) return "";
    return DateFormat('dd/MM/yyyy • HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chats.orderBy('updatedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          "Impossible de charger l'historique.\nVérifiez les règles Firestore pour la collection 'chats'.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return _buildEmpty();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    final msgs = (data['messages'] as List?) ?? [];
                    final last = msgs.isNotEmpty
                        ? (msgs.last['text'] ?? '').toString()
                        : '';
                    final isCurrent = doc.id == currentChatId;

                    return Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(context),
                      onDismissed: (_) => doc.reference.delete(),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: isCurrent
                                  ? _teal.withOpacity(0.5)
                                  : Colors.transparent,
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: ListTile(
                          onTap: () => Navigator.pop(context, doc.id),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: _teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.chat_bubble_outline_rounded,
                                color: _teal, size: 20),
                          ),
                          title: Text(
                            (data['title'] ?? 'Conversation').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text(
                                "${_dateText(data['updatedAt'])} • ${msgs.length} messages",
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 13, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, ''),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Nouvelle conversation",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Historique",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text("Conversations de $babyName • glisser pour supprimer",
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text("Aucune conversation enregistrée",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}