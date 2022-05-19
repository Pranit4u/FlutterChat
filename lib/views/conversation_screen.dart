
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chat/helper/constants.dart';
import 'package:flutter_chat/services/database.dart';
import 'package:flutter_chat/views/webrtc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class ConversationScreen extends StatefulWidget {
  final String chatRoomId;

  ConversationScreen({this.chatRoomId});

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  DatabaseMethods databaseMethods = new DatabaseMethods();
  TextEditingController messageController = new TextEditingController();

  Stream<QuerySnapshot> chatMessagesStream;
  String typingMessageId = "ID_TYPING_" + Constants.myName;

  Widget chatMessageList() {
    return StreamBuilder(
        stream: chatMessagesStream,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DateTime dateTime = new DateTime.fromMillisecondsSinceEpoch(
                        int.parse(snapshot.data.docs[index]["time"]));
                    DateTime now = new DateTime.now();
                    String formattedTime;
                    if (dateTime.day == now.day) {
                      formattedTime = DateFormat.jm().format(dateTime);
                    } else {
                      formattedTime =
                          DateFormat('EEE, MMM d, ' 'yy').format(dateTime);
                    }
                    // if(snapshot.data.docs[index]["type"] == "call"){
                    //   sendVideoCall(snapshot.data.docs[index]["sendBy"] == Constants.myName);
                    //   return Container(height: 0,);
                    // }
                    if (snapshot.data.docs[index].id == typingMessageId) {
                      formattedTime = "typingByMe";
                    } else if (snapshot.data.docs[index].id ==
                        "ID_TYPING_" +
                            widget.chatRoomId
                                .replaceAll("_", "")
                                .replaceAll(Constants.myName, "")) {
                      formattedTime = "typingByOther";
                    } else if (snapshot.data.docs[index]["sendBy"] !=
                            Constants.myName &&
                        snapshot.data.docs[index]["read"] == false) {
                      markAsRead(
                          snapshot.data.docs[index]["message"],
                          snapshot.data.docs[index]["time"],
                          snapshot.data.docs[index]["sendBy"],
                          snapshot.data.docs[index]["sent"],
                          snapshot.data.docs[index]["type"]);
                    }
                    return MessageTile(
                      snapshot.data.docs[index]["message"],
                      snapshot.data.docs[index]["sendBy"] == Constants.myName,
                      formattedTime,
                      snapshot.data.docs[index]["read"],
                      snapshot.data.docs[index]["sent"],
                      snapshot.data.docs[index]["type"],
                    );
                  })
              : Container();
        });
  }

  void markAsRead(
      String message, String time, String sendBy, bool sent, String type) {
    Map<String, dynamic> chatRoomMap = {
      "message": message,
      "sendBy": sendBy,
      "time": time,
      "read": true,
      "sent": sent,
      "type": type
    };
    databaseMethods.addMessageById(widget.chatRoomId, time, chatRoomMap);
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if(state == AppLifecycleState.resumed){
  //
  //   }else{
  //
  //   }
  // }

  @override
  void initState() {
    databaseMethods.getConversationMessages(widget.chatRoomId).then((value) {
      setState(() {
        chatMessagesStream = value;
      });
    });
    super.initState();
  }

  sendMessage({bool sent}) {
    Map<String, dynamic> chatRoomMap = {
      "message": messageController.text,
      "sendBy": Constants.myName,
      "time": DateTime.now().millisecondsSinceEpoch.toString(),
      "read": false,
      "sent": false,
      "type": "text"
    };
    if (sent && messageController.text.isNotEmpty) {
      updateChatRooms(chatRoomMap["message"], chatRoomMap["time"]);
      messageController.text = "";
      databaseMethods
          .addMessageById(widget.chatRoomId, chatRoomMap["time"], chatRoomMap)
          .then((val) {
        messageSent(chatRoomMap);
        print(val);
        sendMessage(sent: false);
      });
    } else if (!sent) {
      chatRoomMap["time"] = int64MaxValue.toString();
      databaseMethods.addMessageById(
          widget.chatRoomId, typingMessageId, chatRoomMap);
    }
  }

  messageSent(Map<String, dynamic> chatRoomMap) {
    chatRoomMap["sent"] = true;
    databaseMethods.addMessageById(
        widget.chatRoomId, chatRoomMap["time"], chatRoomMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoomId
            .replaceAll("_", "")
            .replaceAll(Constants.myName, "")),
        actions: [
          GestureDetector(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.video_call_sharp),
              ),
              onTap: (){
                initiateVideo();
              },
          )
        ],
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: chatMessageList(),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                    color: Color(0x54FFFFFF),
                    borderRadius: BorderRadius.circular(40)),
                padding:
                    EdgeInsets.only(left: 24, right: 14, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                      onChanged: (message) {
                        sendMessage(sent: false);
                      },
                      textAlign: TextAlign.start,
                      maxLines: null,
                      controller: messageController,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type message...",
                          hintStyle: TextStyle(color: Colors.white54)),
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    )),
                    GestureDetector(
                      onTap: () {
                        selectFile();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 40,
                        width: 40,
                        child: Icon(Icons.photo, color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        sendMessage(sent: true);
                      },
                      child: Container(
                          height: 40,
                          width: 40,
                          child: Icon(Icons.send_sharp, color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateChatRooms(String lastMessage, String lastTime) {
    List<String> users = [
      widget.chatRoomId.replaceAll("_", "").replaceAll(Constants.myName, ""),
      Constants.myName
    ];
    Map<String, dynamic> chatRoomMap = {
      "users": users,
      "chatRoomId": widget.chatRoomId,
      "lastMessage": lastMessage,
      "lastTime": lastTime
    };
    databaseMethods.createChatRoom(widget.chatRoomId, chatRoomMap);
  }

  sendFileAlert(BuildContext context, image) {
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Send"),
      onPressed: ()async {
        Navigator.of(context).pop();
        File _image = File(image.path);
        Map<String, dynamic> chatRoomMap = {
          "message": "load",
          "sendBy": Constants.myName,
          "time": DateTime.now().millisecondsSinceEpoch.toString(),
          "read": false,
          "sent": false,
          "type": "loading"
        };
        await databaseMethods.addMessageById(widget.chatRoomId, chatRoomMap["time"], chatRoomMap);
        databaseMethods.uploadFile(_image, widget.chatRoomId, chatRoomMap);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Send Selected File"),
      content: Text("You want to send this file?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void selectFile() async {
    var image = await ImagePicker.platform
        .pickImage(source: ImageSource.gallery, imageQuality: 65);
    if (image == null) {
      print("null image");
      return;
    }
    sendFileAlert(context, image);
  }

  // void initiateVideo() async{
  //   Map<String, dynamic> chatRoomMap = {
  //     "message": "",
  //     "sendBy": Constants.myName,
  //     "time": DateTime.now().millisecondsSinceEpoch.toString(),
  //     "read": false,
  //     "sent": false,
  //     "type": "call"
  //   };
  //   await databaseMethods.addMessageById(widget.chatRoomId, "videoCall", chatRoomMap);
  // }
  void initiateVideo(){
    sendVideoCall(true);
  }

  void sendVideoCall(bool caller)async {
    await Permission.camera.request();
    await Permission.microphone.request();
    Navigator.push(context, MaterialPageRoute(builder: (context) => VideoRenderer(caller: caller, chatRoomId: widget.chatRoomId,)));
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool sendByMe;
  final String time;
  final bool read;
  final bool sent;
  final String type;

  MessageTile(
      this.message, this.sendByMe, this.time, this.read, this.sent, this.type);

  @override
  Widget build(BuildContext context) {
    if (message == "")
      return Container(
        height: 0,
      );
    else if (time == "typingByMe") {
      return Container(
        margin: EdgeInsets.only(top: 8, bottom: 8, left: 74, right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(23)),
          color: Colors.green,
        ),
        child: Container(
          margin: EdgeInsets.only(left: 30),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            message,
            style: TextStyle(fontSize: 17),
            textAlign: TextAlign.end,
          ),
        ),
      );
    } else if (time == "typingByOther") {
      return Container(
        margin: EdgeInsets.only(top: 8, bottom: 8, left: 24, right: 74),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(23)),
          color: Colors.lightGreen,
        ),
        alignment: Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(right: 30),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(message,
              style: TextStyle(fontSize: 17), textAlign: TextAlign.start),
        ),
      );
    } else
      return Container(
          padding: EdgeInsets.only(
              top: 8,
              bottom: 8,
              left: sendByMe ? 0 : 24,
              right: sendByMe ? 24 : 0),
          alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                sendByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (type == "image")
                GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) {
                        return FullScreenImg(
                          url: message,
                        );
                      }));
                    },
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: FadeInImage.assetNetwork(
                              placeholder: "assets/images/giphy.gif",
                              image: message,
                              height: 150,
                              width: 100,
                              fit: BoxFit.fill,
                            ),
                          ),
                          (!sent && sendByMe)
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 5, right: 5),
                                  child: Icon(Icons.access_time,
                                      size: 10, color: Colors.white),
                                )
                              : Container(
                                  height: 0,
                                  width: 0,
                                )
                        ]))
              else if (type == "loading")
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Color(0x54FFFFFF),
                      borderRadius: BorderRadius.circular(40)),
                  child: Text(
                    "Uploading...",
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Container(
                    margin: sendByMe
                        ? EdgeInsets.only(left: 30)
                        : EdgeInsets.only(right: 30),
                    // padding:
                    //     EdgeInsets.only(top: 17, bottom: 17, left: 20, right: 20),
                    decoration: BoxDecoration(
                        borderRadius: sendByMe
                            ? BorderRadius.only(
                                topLeft: Radius.circular(23),
                                topRight: Radius.circular(23),
                                bottomLeft: Radius.circular(23))
                            : BorderRadius.only(
                                topLeft: Radius.circular(23),
                                topRight: Radius.circular(23),
                                bottomRight: Radius.circular(23)),
                        gradient: LinearGradient(
                          colors: sendByMe
                              ? [
                                  const Color(0xff007EF4),
                                  const Color(0xff2A75BC)
                                ]
                              : [
                                  const Color(0x1AFFFFFF),
                                  const Color(0x1AFFFFFF)
                                ],
                        )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding:
                              EdgeInsets.only(top: 17, left: 20, right: 20),
                          child: Text(
                            message,
                            textAlign:
                                sendByMe ? TextAlign.end : TextAlign.start,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        (!sent && sendByMe)
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 5, right: 5),
                                child: Icon(Icons.access_time,
                                    size: 10, color: Colors.white),
                              )
                            : Container(
                                height: 17,
                                width: 0,
                              )
                      ],
                    )),
              Text(
                time,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
              sendByMe && read
                  ? Text(
                      "seen",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    )
                  : Container(
                      height: 0,
                      width: 0,
                    )
            ],
          ));
  }
}

class FullScreenImg extends StatelessWidget {
  final String url;

  const FullScreenImg({Key key, this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Hero(
            tag: 'image',
            child: FadeInImage.assetNetwork(
              placeholder: "assets/images/giphy.gif",
              image: url,
            )),
      ),
    );
  }
}
