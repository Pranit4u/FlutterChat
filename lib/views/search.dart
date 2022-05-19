import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/helper/constants.dart';
import 'package:flutter_chat/services/database.dart';
import 'package:flutter_chat/views/conversation_screen.dart';
import 'package:flutter_chat/widgets/Widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchTextEditingController = new TextEditingController();
  DatabaseMethods databaseMethods = new DatabaseMethods();
  QuerySnapshot querySnapshot;
  bool searching = false;

  initiateSearch(String user){
    setState(() {
      searching = true;
    });
    databaseMethods.getUserByUsername(user).then(
            (val){
          setState(() {
            searching = false;
            querySnapshot = val;
          });});
  }

  createChatRoom(String userName){
    if(userName == Constants.myName){
      Fluttertoast.showToast(
          msg: "Can't message yourself",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1
      );
      return;
    }
    String chatRoomId = getChatRoomId(userName, Constants.myName);
    List<String> users = [userName, Constants.myName];
    Map<String, dynamic> chatRoomMap = {
      "users" : users,
      "chatRoomId" : chatRoomId,
      "lastMessage" : "",
      "lastTime" : "0"
    };
    databaseMethods.checkChatRoom(chatRoomId).then((val){
      if(val.exists){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ConversationScreen(chatRoomId: chatRoomId)));
        return;
      }
    });
    databaseMethods.createChatRoom(chatRoomId, chatRoomMap);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ConversationScreen(chatRoomId: chatRoomId)));


  }

  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  Widget searchList(){
    return querySnapshot == null ? Container(height: 0,)
        : querySnapshot.docs.length == 0 ? Container(alignment: Alignment.center, child: Text("No User Found", style: simpleTextStyle(),),)
        : ListView.builder(
      shrinkWrap: true,
      itemCount: querySnapshot.docs.length,
      itemBuilder: (BuildContext context, int index) {
        return searchTile(
            username: querySnapshot.docs[index]["name"],
            email: querySnapshot.docs[index]["email"]
        );
      },
    );
  }

  Widget searchTile({String username, String email}){
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username, style: simpleTextStyle()),
              Text(email, style: simpleTextStyle())
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: (){
              createChatRoom(username);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.blue
              ),
              child: Text("Message", style: biggerTextStyle()),
            ),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarMain(),
      body: Container(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Color(0x54FFFFFF),
                borderRadius: BorderRadius.circular(30)
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              child: Row(
                children: [
                  Expanded(child: TextField(
                    onChanged: (val){
                      if(val != "") initiateSearch(val);
                    },
                    controller: searchTextEditingController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search username...",
                      hintStyle: TextStyle(color: Colors.white54)
                    ),
                    style: TextStyle(color: Colors.white),
                  )
                  ),
                  GestureDetector(
                    onTap: (){
                      if(searchTextEditingController.text != "") initiateSearch(searchTextEditingController.text);
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0x36FFFFFF),
                            const Color(0x0FFFFFFF)
                          ]
                        ),
                        borderRadius: BorderRadius.circular(40)
                      ),
                      child: Image.asset("assets/images/search_white.png")
                    ),
                  )
                ],
              ),
            ),
            searchList(),
            searching ? Container(alignment: Alignment.center,child: CircularProgressIndicator()) : Container(height: 0,),
          ],
        ),
      ),
    );
  }
}


