//Firebase backend

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gacha_guard/features/auth/domain/models/app_user.dart';
import 'package:gacha_guard/features/auth/domain/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo{

  // access to firebase
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  //login
  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async{
    try {
      //attempt login
      UserCredential userCredential = await firebaseAuth.
      signInWithEmailAndPassword(email: email, password: password);

      //create user
      AppUser user = AppUser(
        uid: userCredential.user!.uid, 
        email: email);

        //return user
        return user;
    } 
    //catch any error
      catch (e) {
        throw Exception('Login Failed: $e');
    }
  }

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name, String email, String password) async{
    try {
      //attempt to signup
      UserCredential userCredential =  await firebaseAuth.
      createUserWithEmailAndPassword(email: email, password: password);

      //create user
      AppUser user = AppUser(uid: userCredential.user!.uid, email: email);

      //return user
      return user;
    } 
    catch (e) {
      throw Exception('Registration failed: $e');
    }
    ;
  }
  
  @override
  Future<void> deleteAccount() async{
    try {
      //get current user
      final user = firebaseAuth.currentUser;

      // check if there is a logged in user
      if (user == null) throw Exception('No user Logged In');

      //delete account
      await user.delete();

      await logout();

    } catch (e) {
      throw Exception('Failed to delete accout: $e');
    }
    
    ;
  }
  
  @override
  Future<AppUser?> getCurrentUser() async{
    //get current logged in user from firebase
    final firebaseUser = firebaseAuth.currentUser;

    //no logged in user
    if (firebaseUser == null) return null;

    //loggedin user exists
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email!);
  }
  
  @override
  Future<void> logout() async{
    await firebaseAuth.signOut();
  }
  
  @override
  Future<String> sendPasswordResetEmail(String email) async{
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return "Password reset email: Check Your Email.";
    } catch (e) {
      return "An Error Occured: $e";
    };
  }
}