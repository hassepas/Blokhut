import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/timer_controller.dart';
import '../theme/studybuddy_theme.dart';
import '../widgets/circle_timer.dart';

class HomeTimerScreen extends StatelessWidget {
  const HomeTimerScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final db = context.read<FirestoreService>();
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Uitloggen',
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<TimerController>(
            builder: (context, timer, _) {
              final label = _fmt(timer.remaining);
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: StudyBuddyTheme.mint.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: CircleTimer(
                              progress: timer.progress,
                              label: label,
                              trackColor: Colors.white.withOpacity(0.7),
                              progressColor: StudyBuddyTheme.mint,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                timer.isRunning ? StudyBuddyTheme.peach : StudyBuddyTheme.mint,
                          ),
                          onPressed: () {
                            if (timer.isRunning) {
                              timer.pause(uid: user.uid, db: db);
                            } else {
                              timer.start(uid: user.uid, db: db);
                            }
                          },
                          icon: Icon(timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          label: Text(timer.isRunning ? 'Pauze' : 'Start'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StudyBuddyTheme.pastelYellow,
                            foregroundColor: const Color(0xFF3B3B3B),
                          ),
                          onPressed: () => timer.stop(uid: user.uid, db: db, complete: false),
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DurationPresets(timer: timer),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DurationPresets extends StatelessWidget {
  final TimerController timer;
  const _DurationPresets({required this.timer});

  @override
  Widget build(BuildContext context) {
    final items = <Duration>[const Duration(minutes: 15), const Duration(minutes: 25), const Duration(minutes: 50)];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((d) {
        final selected = timer.total == d;
        return ChoiceChip(
          selected: selected,
          label: Text('${d.inMinutes}m'),
          onSelected: timer.isRunning
              ? null
              : (_) {
                  // For MVP: rebuild controller not trivial; keep remaining only.
                  timer.setDuration(d);
                },
        );
      }).toList(),
    );
  }
}
