import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save who referred this new user/driver
  static Future<void> saveReferrer({
    required String newUserId,
    required String referralCode,
    required bool isDriver,
  }) async {
    // Determine referrer collection
    final userSnapshot = await _firestore
        .collection('users')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    final driverSnapshot = await _firestore
        .collection('drivers')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    DocumentSnapshot? referrerDoc;
    String? referrerId;
    bool isReferrerDriver = false;

    if (userSnapshot.docs.isNotEmpty) {
      referrerDoc = userSnapshot.docs.first;
      referrerId = referrerDoc.id;
      isReferrerDriver = false;
    } else if (driverSnapshot.docs.isNotEmpty) {
      referrerDoc = driverSnapshot.docs.first;
      referrerId = referrerDoc.id;
      isReferrerDriver = true;
    }

    if (referrerId == null) return;

    final referredCollection = isDriver ? 'drivers' : 'users';

    // Link the referrer to the new user/driver
    await _firestore.collection(referredCollection).doc(newUserId).update({
      'referredBy': referrerId,
      'referrerCode': referralCode,
    });

    // Add to referral history
    await _firestore.collection('referralHistory').add({
      'referrerId': referrerId,
      'referrerType': isReferrerDriver ? 'driver' : 'user',
      'referredId': newUserId,
      'referredType': isDriver ? 'driver' : 'user',
      'timestamp': FieldValue.serverTimestamp(),
      'pointsAwarded': 1,
      'event': 'signup',
    });

    // Add 1 point for any signup via referral
    await _incrementReferralPoints(referrerId, isReferrerDriver, 1);
  }

  /// Add bonus points (e.g., for PRO driver or job completed)
  static Future<void> addReferralPoints({
    required String referredId,
    required int points,
    required String event,
  }) async {
    // Check who referred this person
    final userDoc = await _firestore.collection('users').doc(referredId).get();
    final driverDoc = await _firestore.collection('drivers').doc(referredId).get();

    DocumentSnapshot? doc = userDoc.exists ? userDoc : (driverDoc.exists ? driverDoc : null);
    if (doc == null) return;

    final data = doc.data() as Map<String, dynamic>;
    final referrerId = data['referredBy'];
    final isReferrerDriver = data['referrerType'] == 'driver';

    if (referrerId == null) return;

    // Log and add points
    await _firestore.collection('referralHistory').add({
      'referrerId': referrerId,
      'referrerType': isReferrerDriver ? 'driver' : 'user',
      'referredId': referredId,
      'referredType': driverDoc.exists ? 'driver' : 'user',
      'timestamp': FieldValue.serverTimestamp(),
      'pointsAwarded': points,
      'event': event,
    });

    await _incrementReferralPoints(referrerId, isReferrerDriver, points);
  }

  /// Internal helper: Add points to user or driver profile
  static Future<void> _incrementReferralPoints(
      String userId, bool isDriver, int points) async {
    final collection = isDriver ? 'drivers' : 'users';

    final docRef = _firestore.collection(collection).doc(userId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      final current = snapshot.data()?['referralPoints'] ?? 0;
      tx.update(docRef, {'referralPoints': current + points});
    });
  }
}
