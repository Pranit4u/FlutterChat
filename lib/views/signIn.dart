import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/helper/helperfunctions.dart';
import 'package:flutter_chat/services/auth.dart';
import 'package:flutter_chat/services/database.dart';
import 'package:flutter_chat/widgets/Widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'chatRoomScreen.dart';

class SignIn extends StatefulWidget {
  final Function toggle;
  SignIn(this.toggle);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  AuthMethods authMethods = new AuthMethods();
  DatabaseMethods databaseMethods = new DatabaseMethods();
  QuerySnapshot userInfoSnapshot;
  bool isLoading = false;
  final formKey = GlobalKey<FormState>();
  TextEditingController emailTextEditingController = new TextEditingController();
  TextEditingController passwordTextEditingController = new TextEditingController();

  signMeIn(){
    if(formKey.currentState.validate()){
      HelperFunctions.saveEmailIdPref(emailTextEditingController.text);
      setState(() {
        isLoading = true;
      });
      authMethods.signInWithEmailAndPassword(emailTextEditingController.text,
          passwordTextEditingController.text)
          .then((value){
            if(value != null){
              databaseMethods.getUserByEmailId(emailTextEditingController.text).then(
                  (val){
                    userInfoSnapshot = val;
                    HelperFunctions.saveUserNamePref(userInfoSnapshot.docs[0]["name"]);
                    HelperFunctions.saveLoggedInPref(true);
                    print("${value.userId}");
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChatRoom()));
                  }
              );
            }else{
              setState(() {
                isLoading = false;
              });
            }
      });
    }
  }
  resetPassword(String email){
    databaseMethods.getUserByEmailId(email).then((val){
      if(val.docs.length != 0){
        authMethods.resetPassword(email);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("New Password has been sent to your email")));
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User with provided email not found")));
      }
    });
  }
  onForgotPassword() {
    String email = emailTextEditingController.text;
    if (RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email)) {
      resetPassword(email);
       }
    else {
      Fluttertoast.showToast(
          msg: "Provide correct email id",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1
      );
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
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: (){
                        onForgotPassword();
                      },
                      child: Container(
                          alignment: Alignment.centerRight,
                          child: Container(
                            child: Text("forgot password?", style: simpleTextStyle()),
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          )
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: (){
                        signMeIn();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: isLoading ? CircularProgressIndicator(backgroundColor: Colors.white) : Text("SignIn", style: TextStyle(
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
                      child: Text("SignIn with Google",style: TextStyle(
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
                        Text("Don't have account?", style: simpleTextStyle()),
                        GestureDetector(
                          onTap: () {
                            widget.toggle();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text("SignUp Now", style: TextStyle(
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
        )
        );
  }
}
