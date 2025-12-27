import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> sessionCol(String uid) =>
      _db.collection('sessions').doc(uid).collection('items');

  CollectionReference<Map<String, dynamic>> notificationCol(String uid) =>
      _db.collection('notifications').doc(uid).collection('items');

  Future<void> upsertUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    await userRef(uid).set(
      {
        'name': name,
        'email': email,
        'friends': FieldValue.arrayUnion(<String>[]),
        'isStudying': false,
        'currentSessionStart': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<Map<String, dynamic>?> streamUser(String uid) {
    return userRef(uid).snapshots().map((d) => d.data());
  }

  /// Stream friends' user docs.
  ///
  /// Note: Firestore `whereIn` has a hard limit (often 10). For MVP we take the first 10.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamFriendsUsers(List<String> friendUids) {
    if (friendUids.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendUids.take(10).toList())
        .snapshots();
  }

  Future<void> setStudyingStatus({
    required String uid,
    required bool isStudying,
    Timestamp? currentSessionStart,
  }) async {
    await userRef(uid).update({
      'isStudying': isStudying,
      'currentSessionStart': currentSessionStart,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addSession({
    required String uid,
    required DateTime start,
    required DateTime end,
  }) async {
    final duration = end.difference(start).inSeconds;
    await sessionCol(uid).add({
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'duration': duration,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSessionsBetween({
    required String uid,
    required DateTime from,
    required DateTime to,
  }) {
    return sessionCol(uid)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start', isLessThan: Timestamp.fromDate(to))
        .orderBy('start', descending: false)
        .snapshots();
  }

  Future<String?> findUserUidByEmail(String email) async {
    final q = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }

  Future<void> addFriendByUid({
    required String myUid,
    required String friendUid,
  }) async {
    await userRef(myUid).update({'friends': FieldValue.arrayUnion([friendUid])});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications(String uid) {
    return notificationCol(uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }
}
