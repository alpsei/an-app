import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  Future<void> mesajGonder(String odaID, String mesaj) async {
    String username = 'Bilinmeyen';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      if (doc.exists) {
        username = doc['username'] ?? 'Bilinmeyen'; // 'username' varsa al, yoksa 'Bilinmeyen' kullan
      }
    }).catchError((e) {
      print("Hata: $e");
    });

    await _firestore.collection('odalar').doc(odaID).collection('mesajlar').add({
      'mesaj': mesaj,
      'gonderen': username,  // Burada 'gonderen' username ile güncellenmiş oldu
      'gonderenUid': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': Timestamp.now(),
    });
  }


  // mesajları dinle
Stream<QuerySnapshot> mesajlariDinle(String odaID)
{
  return _firestore.collection('odalar').doc(odaID).collection('mesajlar')
      .orderBy('timestamp', descending: true)
      .snapshots();
}
}
