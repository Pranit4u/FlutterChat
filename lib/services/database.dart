
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseMethods{

  getUserByUsername(String username) async{
    return await FirebaseFirestore.instance.collection("users")
        .where("name", isGreaterThanOrEqualTo: username).where("name", isLessThan: username + "\uf8ff").get();
  }

  getUserByEmailId(String emailId) async{
    return await FirebaseFirestore.instance.collection("users")
        .where("email", isEqualTo: emailId).get();
  }

  uploadUserInfo(userMap){
    FirebaseFirestore.instance.collection("users")
        .add(userMap).catchError((e){
          print(e.toString());
    });
  }

  createChatRoom(String chatRoomId, chatRoomMap){
    FirebaseFirestore.instance.collection("ChatRoom")
        .doc(chatRoomId).set(chatRoomMap).catchError((e){
          print(e.toString());
    });
  }

  addMessageById(String chatRoomId,String messageId, Map<String, dynamic> chatRoomMap)async{
    return await FirebaseFirestore.instance.collection("ChatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId).set(chatRoomMap)
        .catchError((e){
          print(e.toString());
    });
  }

  uploadFile(File file, String chatRoomId, Map<String, dynamic> chatRoomMap) async{
    if(file == null) return;
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("image" + DateTime.now().toString());
    UploadTask uploadTask = ref.putFile(file);
    uploadTask.whenComplete(() async {
      String url = await ref.getDownloadURL();
      if(url == null) return;
      chatRoomMap["message"] = url;
      chatRoomMap["type"] = "image";
      await addMessageById(chatRoomId, chatRoomMap["time"], chatRoomMap);
      chatRoomMap["sent"] = true;
      return await addMessageById(chatRoomId, chatRoomMap["time"], chatRoomMap);
    }).catchError((onError){
      print(onError);
    });
  }


  deleteMessage(String messageId, String chatRoomId) async{
    await FirebaseFirestore.instance.collection("ChatRoom")
        .doc(chatRoomId)
        .collection("chats").doc(messageId).delete();
  }

  getConversationMessages(String chatRoomId) async{
    return await FirebaseFirestore.instance.collection("ChatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots();
  }

  getvcStream(String chatRoomId) async{
    return await FirebaseFirestore.instance.collection("ChatRoom")
        .doc(chatRoomId)
        .collection("webrtc").snapshots();
  }
  // getvcStream(String chatRoomId) async{
  //   FirebaseFirestore.instance.collection("ChatRoom")
  //       .doc(chatRoomId)
  //       .collection("webrtc").snapshots().listen((querySnapshots) {
  //         querySnapshots.docChanges.forEach((element) {
  //           return element;
  //         });
  //   });
  // }

  
  getChatRooms(String userName)async{
    return await FirebaseFirestore.instance.collection("ChatRoom")
        .orderBy("lastTime", descending: true)
        .where("users", arrayContains: userName)
        .snapshots();
  }

  checkChatRoom(String chatRoomId) async{
    return await FirebaseFirestore.instance.collection("ChatRoom")
        .doc(chatRoomId).get();
  }


}