import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/helper/authenticate.dart';
import 'package:flutter_chat/helper/constants.dart';
import 'package:flutter_chat/helper/helperfunctions.dart';
import 'package:flutter_chat/services/auth.dart';
import 'package:flutter_chat/services/database.dart';
import 'package:flutter_chat/views/conversation_screen.dart';
import 'package:flutter_chat/views/search.dart';
import 'package:intl/intl.dart';

class ChatRoom extends StatefulWidget {
  const ChatRoom({Key key}) : super(key: key);

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  AuthMethods authMethods = new AuthMethods();
  DatabaseMethods databaseMethods = new DatabaseMethods();
  Stream<QuerySnapshot> allChatsStream;
  bool isLoading = false;

  @override
  void initState() {
    getAllChatRooms();
    super.initState();
  }

  signOutUser() {
    setState(() {
      isLoading = true;
    });
    authMethods.signOut().then((val){
      HelperFunctions.saveLoggedInPref(false);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Authenticate()));
          isLoading = false;
      });
  }
  getAllChatRooms()async{
    Constants.myName = await HelperFunctions.getUserNamePref();
    databaseMethods.getChatRooms(Constants.myName)
        .then((value){
          setState(() {
            allChatsStream = value;
          });
    });
  }

  Widget getChatRoomList(){
    return StreamBuilder(
      stream: allChatsStream,
        builder: (context, snapshot){
        return snapshot.hasData ? ListView.builder(
          shrinkWrap: true,
          itemCount: snapshot.data.docs.length,
            itemBuilder: (context, index){
            return ChatRoomsTile(
              userName: snapshot.data.docs[index]["chatRoomId"]
                  .toString()
                  .replaceAll("_", "")
                  .replaceAll(Constants.myName, ""),
              chatRoomId: snapshot.data.docs[index]["chatRoomId"],
              lastTime: snapshot.data.docs[index]["lastTime"],
              lastMessage: snapshot.data.docs[index]["lastMessage"]
            );
            }
        ) : Container();
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MR ' Connect"),
        actions: [
          GestureDetector(
            onTap: (){
              showSignOutAlert(context);
            },
            child: isLoading ? CircularProgressIndicator() : Container(padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.exit_to_app)),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
        },
      ),
      body: Container(
        child: getChatRoomList(),
      )
    );
  }

  showSignOutAlert(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed:  () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: Text("SignMeOut"),
      onPressed:  () {
        Navigator.of(context).pop();
        signOutUser();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Sign Out?"),
      content: Text("You will be signed out!"),
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

}

class ChatRoomsTile extends StatelessWidget {
  final String userName;
  final String chatRoomId;
  final String lastTime;
  final String lastMessage;

  ChatRoomsTile({this.userName,@required this.chatRoomId, this.lastTime, this.lastMessage});

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = new DateTime.fromMillisecondsSinceEpoch(int.parse(lastTime));
    DateTime now = new DateTime.now();
    String formattedTime;
    int endIndex = lastMessage.length < 30 ? 0 : 30;
    if (dateTime.day == now.day) {
      formattedTime = DateFormat.jm().format(dateTime);
    } else {
      formattedTime =
          DateFormat('EEE, MMM d, ' 'yy').format(dateTime);
    }
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => ConversationScreen(
              chatRoomId: chatRoomId,
            )
        ));
      },
      child: Container(
        color: Colors.black26,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                    color: Theme.of(context).accentColor,
                    borderRadius: BorderRadius.circular(30)),
                child: Center(
                  child: Text(userName.substring(0, 1),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,)),
              ),
            ),
            SizedBox(
              width: 12,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,)),
                Text(endIndex == 0 ? lastMessage : lastMessage.substring(0, endIndex),style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,))
              ],
            ),
            Spacer(),
            Container(
              alignment: Alignment.centerRight,
              child: Text(formattedTime,style: TextStyle(
                color: Colors.white,
                fontSize: 10,)),
            )
          ],
        ),
      ),
    );
  }

}

