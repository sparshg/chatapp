import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Database {
  /// The main Firestore user collection
  static CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  static CollectionReference chatRooms =
      FirebaseFirestore.instance.collection('rooms');
  static CollectionReference dms = FirebaseFirestore.instance.collection('dms');

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

  static Future<void> createDm(String email) async {
    FirebaseFirestore.instance
        .collection('dms')
        .doc("${FirebaseAuth.instance.currentUser!.email}_$email")
        .set({
      "chatroomid": "${FirebaseAuth.instance.currentUser!.email}_$email",
    });
  }

  static Future<void> createRoom(String uid, String username,
      List<String> otheruids, List<String> usernames, String roomname) async {
    otheruids.add(uid);
    usernames.add(username);
    final room =
        await chatRooms.add({'users': FieldValue.arrayUnion(usernames)});
    room.update({'groupName': roomname});
    room.update({'groupRoomId': room.id});
    // for (String id in otheruids) {
    //   userCollection.doc(id).update({
    //     'rooms': FieldValue.arrayUnion([room.id])
    //   });
    // }
  }

  static void pushMessage(String message, String roomid, bool dm) async {
    if (dm) {
      await FirebaseFirestore.instance.collection('dms/$roomid/CHATS').add({
        'sendBy': FirebaseAuth.instance.currentUser!.displayName!,
        'message': message,
        'time': Timestamp.now().millisecondsSinceEpoch
      });
    } else {
      await FirebaseFirestore.instance.collection('rooms/$roomid/chats').add({
        'sendBy': FirebaseAuth.instance.currentUser!.displayName!,
        'message': message,
        'time': Timestamp.now().millisecondsSinceEpoch
      });
    }
  }

  static Stream<QuerySnapshot> retrieveUsers() => userCollection.snapshots();

  static Stream<QuerySnapshot> retrieveRooms(bool dm) {
    // print("Gettins rooms");
    // List rooms =
    //     await userCollection.doc(uid).get().then((user) => user.get('rooms'));
    // List docs = await Future.wait(
    //     rooms.map((room) async => await chatRooms.doc(room).get()).toList());
    // return docs;
    if (dm) {
      return dms
          .where('users',
              arrayContains: FirebaseAuth.instance.currentUser!.displayName!)
          .snapshots();
    }
    return chatRooms
        .where('users',
            arrayContains: FirebaseAuth.instance.currentUser!.displayName!)
        .snapshots();
  }

  static Stream<QuerySnapshot> retrieveChats(String roomid, bool dm) {
    if (dm) {
      return FirebaseFirestore.instance
          .collection('dms/$roomid/CHATS')
          .orderBy('time')
          .snapshots();
    }
    return FirebaseFirestore.instance
        .collection('rooms/$roomid/chats')
        .orderBy('time')
        .snapshots();
  }

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
