import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  /// The main Firestore user collection
  static CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  static Future<void> storeUserData(
      {required String userName,
      required String userEmail,
      required String uid}) async {
    DocumentReference documentReferencer = userCollection.doc(uid);
    User user = User(name: userName, email: userEmail);
    var data = user.toJson();

    await documentReferencer.set(data).whenComplete(() {
      log("User data added");
    }).catchError((e) => log(e));
  }

  static Stream<QuerySnapshot> retrieveUsers() => userCollection.snapshots();
}

class User {
  String? name;
  String? email;

  User({
    required this.name,
    required this.email,
  });

  User.fromJson(Map<String, dynamic> json) {
    name = json['userName'];
    email = json['userEmail'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userName'] = name;
    data['userEmail'] = email;
    return data;
  }
}
