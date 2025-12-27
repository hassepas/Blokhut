import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

class TimerController extends ChangeNotifier {
  TimerController({Duration initialDuration = const Duration(minutes: 25)}) {
    _total = initialDuration;
    _remaining = initialDuration;
  }

  Timer? _timer;
  DateTime? _sessionStart;
  late Duration _total;
  late Duration _remaining;
  bool _isRunning = false;

  Duration get total => _total;
  Duration get remaining => _remaining;
  bool get isRunning => _isRunning;

  double get progress {
    final totalSeconds = _total.inSeconds;
    if (totalSeconds <= 0) return 0;
    return 1 - (_remaining.inSeconds / totalSeconds);
  }

  void setDuration(Duration d) {
    if (_isRunning) return;
    _total = d;
    _remaining = d;
    notifyListeners();
  }

  void start({required String uid, required FirestoreService db}) {
    if (_isRunning) return;
    _isRunning = true;
    _sessionStart ??= DateTime.now();

    db.setStudyingStatus(
      uid: uid,
      isStudying: true,
      currentSessionStart: Timestamp.fromDate(_sessionStart!),
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        stop(uid: uid, db: db, complete: true);
      } else {
        _remaining -= const Duration(seconds: 1);
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void pause({required String uid, required FirestoreService db}) {
    if (!_isRunning) return;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;

    // Still keep the session open; user can resume.
    db.setStudyingStatus(uid: uid, isStudying: false, currentSessionStart: null);
    notifyListeners();
  }

  Future<void> stop({
    required String uid,
    required FirestoreService db,
    bool complete = false,
  }) async {
    _timer?.cancel();
    _timer = null;

    final start = _sessionStart;
    final end = DateTime.now();

    _isRunning = false;
    _sessionStart = null;

    if (start != null) {
      final effectiveEnd = complete ? start.add(_total) : end;
      await db.addSession(uid: uid, start: start, end: effectiveEnd);
    }

    await db.setStudyingStatus(uid: uid, isStudying: false, currentSessionStart: null);

    _remaining = _total;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
