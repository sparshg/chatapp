import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Database {
  /// The main Firestore user collection
  static CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  static CollectionReference chatRooms =
      FirebaseFirestore.instance.collection('rooms');

  static Future<void> storeUserData(
      {required String userName,
      required String userEmail,
      required String uid}) async {
    DocumentReference documentReferencer = userCollection.doc(uid);
    var data = {'userName': userName, 'userEmail': userEmail, 'rooms': []};

    await documentReferencer.set(data).whenComplete(() {
      log("User data added");
    }).catchError((e) => log(e));
  }

  static Future<void> createRoom(String uid, String username,
      List<String> otheruids, List<String> usernames) async {
    otheruids.add(uid);
    usernames.add(username);
    final room =
        await chatRooms.add({'users': FieldValue.arrayUnion(usernames)});
    for (String id in otheruids) {
      userCollection.doc(id).update({
        'rooms': FieldValue.arrayUnion([room.id])
      });
    }
  }

  static void pushMessage(String message, String roomid) async {
    await FirebaseFirestore.instance.collection('rooms/$roomid/chats').add({
      'userName': FirebaseAuth.instance.currentUser!.displayName!,
      'message': message,
      'time': Timestamp.now().millisecondsSinceEpoch
    });
  }

  static Stream<QuerySnapshot> retrieveUsers() => userCollection.snapshots();

  static Future<List> retrieveRooms(String uid) async {
    List rooms =
        await userCollection.doc(uid).get().then((user) => user.get('rooms'));
    List docs = await Future.wait(
        rooms.map((room) async => await chatRooms.doc(room).get()).toList());
    return docs;
  }

  static Stream<QuerySnapshot> retrieveChats(String roomid) =>
      FirebaseFirestore.instance
          .collection('rooms/$roomid/chats')
          .orderBy('time')
          .snapshots();

  static Future<void> deleteRoom(String roomid) async {
    userCollection.doc(FirebaseAuth.instance.currentUser!.uid).update({
      'rooms': FieldValue.arrayRemove([roomid])
    });
    chatRooms.doc(roomid).update({
      'users': FieldValue.arrayRemove(
          [FirebaseAuth.instance.currentUser!.displayName!])
    });
  }
}
