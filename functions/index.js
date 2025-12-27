const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Trigger: when a user toggles isStudying from false -> true, notify their friends.
exports.notifyFriendsOnStudyStart = functions.firestore
  .document('users/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;
    const wasStudying = !!before.isStudying;
    const isStudying = !!after.isStudying;

    // Only on rising edge.
    if (wasStudying || !isStudying) return null;

    const uid = context.params.uid;
    const name = after.name || 'Je vriend';
    const friends = Array.isArray(after.friends) ? after.friends : [];
    if (friends.length === 0) return null;

    // Load tokens for friends.
    const friendDocs = await Promise.all(
      friends.map(fid => admin.firestore().collection('users').doc(fid).get())
    );

    const tokens = friendDocs
      .map(d => (d.exists ? d.data().fcmToken : null))
      .filter(t => typeof t === 'string' && t.length > 0);

    if (tokens.length === 0) return null;

    const payload = {
      notification: {
        title: `${name} is gestart met studeren!`,
        body: 'Tik om te kijken wie er nu studeert.'
      },
      data: {
        type: 'friend_study_start',
        friendUid: uid
      }
    };

    // Send push.
    const resp = await admin.messaging().sendEachForMulticast({
      tokens,
      ...payload
    });

    // Write in-app notifications per friend (for the "Meldingen" list).
    const batch = admin.firestore().batch();
    const now = admin.firestore.FieldValue.serverTimestamp();

    friends.forEach(fid => {
      const ref = admin.firestore().collection('notifications').doc(fid).collection('items').doc();
      batch.set(ref, {
        title: `${name} is gestart met studeren!`,
        body: '',
        createdAt: now,
        type: 'friend_study_start',
        friendUid: uid
      });
    });

    await batch.commit();

    return {
      sent: resp.successCount,
      failed: resp.failureCount
    };
  });
