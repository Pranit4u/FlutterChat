import 'package:flutter/material.dart';
import 'package:flutter_chat/helper/helperfunctions.dart';
import 'package:flutter_chat/services/auth.dart';
import 'package:flutter_chat/services/database.dart';
import 'package:flutter_chat/widgets/Widgets.dart';

import 'chatRoomScreen.dart';

class SignUp extends StatefulWidget {
  final Function toggle;
  SignUp(this.toggle);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

  DatabaseMethods databaseMethods = new DatabaseMethods();
  AuthMethods authMethods = new AuthMethods();
  bool isLoading = false;
  final formKey = GlobalKey<FormState>();
  TextEditingController usernameTextEditingController = new TextEditingController();
  TextEditingController emailTextEditingController = new TextEditingController();
  TextEditingController passwordTextEditingController = new TextEditingController();

  signMeUp(){
    if(formKey.currentState.validate()){
      Map<String, String> userMap = {
        "name" : usernameTextEditingController.text,
        "email" : emailTextEditingController.text
      };

      HelperFunctions.saveUserNamePref(usernameTextEditingController.text);
      HelperFunctions.saveEmailIdPref(emailTextEditingController.text);

      setState(() {
        isLoading = true;
      });
      authMethods.signUpWithEmailAndPassword(emailTextEditingController.text,
          passwordTextEditingController.text)
      .then((value){
        if(value != null){
          HelperFunctions.saveLoggedInPref(true);
          databaseMethods.uploadUserInfo(userMap);
          print("${value.userId}");
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatRoom()));
        }else{
          setState(() {
            isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarMain(),
      body: SingleChildScrollView(
        child: Container(
            height: MediaQuery.of(context).size.height - 50,
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          validator: (val){
                            return val.isEmpty || val.length < 3 ? "Enter Username 3+ characters" : null;
                          },
                            controller: usernameTextEditingController,
                            decoration: textFieldInputDecoration("username"),
                            style: simpleTextStyle()
                        ),
                        TextFormField(
                          validator: (val){
                            return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val) ?
                            null : "Enter correct email";
                          },
                            controller: emailTextEditingController,
                            decoration: textFieldInputDecoration("email"),
                            style: simpleTextStyle()
                        ),
                        TextFormField(
                            validator:  (val){
                              return val.length < 6 ? "Enter Password 6+ characters" : null;
                            },
                            obscureText: true,
                            controller: passwordTextEditingController,
                            decoration: textFieldInputDecoration("password"),
                            style: simpleTextStyle()
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: (){
                      signMeUp();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: isLoading ? CircularProgressIndicator(backgroundColor: Colors.white) : Text("SignUp", style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.0
                      ),),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          const Color(0xff007EF4),
                          const Color(0xff2A75BC)
                        ]),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text("SignUp with Google",style: TextStyle(
                        color: Colors.black,
                        fontSize: 17.0
                    ),),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?", style: simpleTextStyle()),
                      GestureDetector(
                        onTap: () {
                          widget.toggle();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("SignIn Now", style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.0,
                              decoration: TextDecoration.underline
                          )),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 50),
                ],
              ),
            )
        ),
      ),
    );
  }
}
