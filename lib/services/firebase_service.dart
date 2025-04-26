import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // oda açma
  Future<String> odaAc(String youtubeURL) async {
    var uuid = const Uuid();
    String odaID = uuid.v4();
    await _firestore.collection('odalar').doc(odaID).set({
      'odaID': odaID,
      'videoURL': youtubeURL,
      'createdAt': FieldValue.serverTimestamp()
    });
    return odaID;
  }

  // odaya katılma
  Future<String?> odaBilgisiAl(String odaID) async {
    var oda = await _firestore.collection('odalar').doc(odaID).get();
    if (oda.exists) {
      return oda['videoURL'];
    }
    return null;
  }

  // mesaj gönder
  Future<void> mesajGonder(String odaID, Map<String, dynamic> messageData) async {
    try {
      String username = 'Bilinmeyen';

      // Kullanıcı bilgilerini al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        username = userDoc['username'] ?? 'Bilinmeyen';
      }

      // Mesaj verilerini hazırla
      final message = {
        'mesaj': messageData['mesaj'],
        'gonderen': username,
        'gonderenUid': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Eğer alıntı varsa ekle
      if (messageData.containsKey('replyTo') && messageData['replyTo'] != null) {
        message['replyTo'] = {
          'messageText': messageData['replyTo']['messageText'],
          'senderUsername': messageData['replyTo']['senderUsername'],
        };
      }

      // Mesajı gönder
      await _firestore
          .collection('odalar')
          .doc(odaID)
          .collection('mesajlar')
          .add(message);
    } catch (e) {
      print("Mesaj gönderme hatası: $e");
      rethrow;
    }
  }

  // mesajları dinle
  Stream<QuerySnapshot> mesajlariDinle(String odaID) {
    return _firestore
        .collection('odalar')
        .doc(odaID)
        .collection('mesajlar')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
