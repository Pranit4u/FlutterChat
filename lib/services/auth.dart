import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat/modal/aUser.dart';

class AuthMethods{

  final FirebaseAuth _auth = FirebaseAuth.instance;

  AUser _getUserFromFirebaseUser(User user){
    if(user == null) return null;
    return AUser(user.uid);
  }

  Future signInWithEmailAndPassword(String email, String password) async{
    try{
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User user = result.user;
      return _getUserFromFirebaseUser(user);
    }catch(e){
      print(e.toString());
    }
  }

  Future signUpWithEmailAndPassword(String email, String password) async{
    try{
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User user = result.user;
      return _getUserFromFirebaseUser(user);
    }catch(e){
      print(e.toString());
    }
  }

  Future resetPassword(String email) async{
    try{
      return await _auth.sendPasswordResetEmail(email: email);
    }catch(e){
      print(e.toString());
    }
  }

  Future signOut() async{
    try{
      return await _auth.signOut();
    }catch(e){
      print(e.toString());
    }
  }
}