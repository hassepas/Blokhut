import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../theme/studybuddy_theme.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final db = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vrienden'),
        actions: [
          IconButton(
            tooltip: 'Vriend toevoegen',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _addFriendDialog(context, db, user.uid),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>?>(
          stream: db.streamUser(user.uid),
          builder: (context, snap) {
            final data = snap.data;
            final friends = (data?['friends'] as List?)?.cast<String>() ?? <String>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Studeert nu', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _StudyingNowList(friendUids: friends),
                const SizedBox(height: 18),
                Text('Meldingen', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                _NotificationsList(uid: user.uid),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _addFriendDialog(BuildContext context, FirestoreService db, String myUid) async {
    final controller = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Vriend toevoegen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Voeg toe op basis van e-mail (moet al geregistreerd zijn).'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'E-mail van vriend'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuleren')),
                FilledButton(
                  onPressed: () async {
                    final email = controller.text.trim();
                    if (!email.contains('@')) {
                      setState(() => error = 'Ongeldig e-mailadres');
                      return;
                    }
                    final friendUid = await db.findUserUidByEmail(email);
                    if (friendUid == null) {
                      setState(() => error = 'Geen gebruiker gevonden voor dit e-mailadres');
                      return;
                    }
                    if (friendUid == myUid) {
                      setState(() => error = 'Je kan jezelf niet toevoegen');
                      return;
                    }
                    await db.addFriendByUid(myUid: myUid, friendUid: friendUid);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Toevoegen'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }
}

class _StudyingNowList extends StatelessWidget {
  final List<String> friendUids;
  const _StudyingNowList({required this.friendUids});

  @override
  Widget build(BuildContext context) {
    final db = context.read<FirestoreService>();

    if (friendUids.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Nog geen vrienden. Gebruik de knop rechtsboven om iemand toe te voegen.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.streamFriendsUsers(friendUids),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        final studying = docs.where((d) => (d.data()['isStudying'] == true)).toList();

        if (studying.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Niemand is op dit moment aan het studeren.', style: Theme.of(context).textTheme.bodyLarge),
            ),
          );
        }

        return Column(
          children: studying.map((d) {
            final m = d.data();
            final name = (m['name'] ?? 'Vriend') as String;
            return Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: StudyBuddyTheme.mint, child: Icon(Icons.person, color: Colors.white)),
                title: Text(name),
                subtitle: const Text('Aan het studeren...'),
                trailing: const Icon(Icons.circle, color: StudyBuddyTheme.mint, size: 14),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final String uid;
  const _NotificationsList({required this.uid});

  @override
  Widget build(BuildContext context) {
    final db = context.read<FirestoreService>();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.streamNotifications(uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nog geen meldingen.', style: Theme.of(context).textTheme.bodyLarge),
            ),
          );
        }

        return Column(
          children: docs.map((d) {
            final m = d.data();
            final title = (m['title'] ?? 'Melding') as String;
            final body = (m['body'] ?? '') as String;
            final ts = m['createdAt'] as Timestamp?;
            final when = ts == null
                ? ''
                : '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active_rounded, color: StudyBuddyTheme.peach),
                title: Text(title),
                subtitle: Text(body.isEmpty ? when : '$body\n$when'),
                isThreeLine: body.isNotEmpty,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
