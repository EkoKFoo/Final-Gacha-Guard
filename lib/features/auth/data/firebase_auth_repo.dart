//Firebase backend

import 'package:firebase_auth/firebase_auth.dart';
import 'package:gacha_guard/features/auth/domain/models/app_user.dart';
import 'package:gacha_guard/features/auth/domain/repos/auth_repo.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthRepo implements AuthRepo{

  // access to firebase
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

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
  //register
  @override
  Future<AppUser?> registerWithEmailPassword(
    String name, String email, String password) async{
    try {
      //attempt to signup
      UserCredential userCredential =  await firebaseAuth.
      createUserWithEmailAndPassword(email: email, password: password);

      //create user
      AppUser user = AppUser(uid: userCredential.user!.uid, email: email);

      //save user data in firestore
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'phone': '',
        'photo': null, 
        'createdAt': FieldValue.serverTimestamp(),
        'notification': true,
        'updatedAt': FieldValue.serverTimestamp(),
        });

      //return user
      return user;
    } 
    catch (e) {
      throw Exception('Registration failed: $e');
    }
  }
  //delete Account
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
  //get current user
  @override
  Future<AppUser?> getCurrentUser() async{
    //get current logged in user from firebase
    final firebaseUser = firebaseAuth.currentUser;

    //no logged in user
    if (firebaseUser == null) return null;

    //loggedin user exists
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email!);
  }
  //logout
  @override
  Future<void> logout() async{
    final user = firebaseAuth.currentUser;

    if (user != null) {
      try {
        // Only sign out from Google if the user signed in with Google
        if (user.providerData.any((p) => p.providerId == 'google.com')) {
          await googleSignIn.signOut();
        }

        // Sign out from Firebase
        await firebaseAuth.signOut();
      } catch (e) {
        throw Exception('Logout failed: $e');
      }
    }
  }
  
  //password reset email
  @override
  Future<String> sendPasswordResetEmail(String email) async{
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return "Password reset email: Check Your Email.";
    } catch (e) {
      return "An Error Occured: $e";
    };
  }

    @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Get GoogleSignIn instance
      final googleSignIn = GoogleSignIn.instance;
      
      // Initialize if needed (only once)
      await googleSignIn.initialize();
      
      // Authenticate the user
      final GoogleSignInAccount gUser = await googleSignIn.authenticate();
      
      // Get authentication details
      final authentication = await gUser.authentication;
      
      // Get ID token (required for Firebase)
      final String? idToken = authentication.idToken;
      
      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // Get access token 
      final authClient = gUser.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email']);
      final String? accessToken = authorization?.accessToken;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // Get Firebase user
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase user is null after sign-in');
      }

      // Check if user document exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      // If user doesn't exist, create new document
      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'name': firebaseUser.displayName ?? '',
          'phone': '',
          'photo': firebaseUser.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'notification': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing user's updatedAt timestamp
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create and return your AppUser
      final appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
      );

      return appUser;
      
    } 
    catch (e) {
        throw Exception('Login Failed: $e');
    }
  }
}