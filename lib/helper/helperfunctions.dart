
import 'package:shared_preferences/shared_preferences.dart';

class HelperFunctions{
  static String loggedInKey = "ISLOGGEDIN";
  static String userNameKey = "USERNAME";
  static String emailIdKey = "EMAIL";

  static Future<bool> saveLoggedInPref(bool isLoggedIn) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setBool(loggedInKey, isLoggedIn);
  }

  static Future<bool> saveUserNamePref(String userName) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setString(userNameKey, userName);
  }

  static Future<bool> saveEmailIdPref(String emailId) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setString(loggedInKey, emailId);
  }

  static Future<bool> getLoggedInPref() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(loggedInKey);
  }

  static Future<String> getUserNamePref() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(userNameKey);
  }

  static Future<String> getEmailIdPref() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getString(emailIdKey);
  }
}