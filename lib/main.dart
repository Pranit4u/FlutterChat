import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/helper/authenticate.dart';
import 'package:flutter_chat/views/chatRoomScreen.dart';
import 'package:flutter_chat/views/webrtc.dart';

import 'helper/helperfunctions.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool userIsLoggedIn;

  @override
  void initState() {
    getLoggedInState();
    super.initState();
  }

  getLoggedInState()async{
    await HelperFunctions.getLoggedInPref().then((value){
      setState(() {
        userIsLoggedIn  = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chat Application",
      debugShowCheckedModeBanner: false,
      home: userIsLoggedIn != null ?  userIsLoggedIn ? ChatRoom() : Authenticate()
          : Container(
        child: Center(
          child: Authenticate(),
        ),
      ),
      theme: ThemeData(
          primaryColor: Colors.indigo,
          scaffoldBackgroundColor: Color(0xff1F1F1F),
      ),
    );
  }
}





