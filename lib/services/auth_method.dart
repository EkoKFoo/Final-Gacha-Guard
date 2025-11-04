// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// // Google Sign-In Service Class
// class GoogleSignInService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
//   static bool isInitialize = false;

//   static Future<void> initSignIn() async {
//     if (!isInitialize) {
//       await _googleSignIn.initialize(
//         serverClientId:
//             '878128902123-099iqlbl83n5ipd7tm2bgnn8oj19hu0a.apps.googleusercontent.com',
//       );
//     }
//     isInitialize = true;
//   }
//   // Sign in with Google
//   static Future<UserCredential?> signInWithGoogle() async {
//     try {
//       initSignIn();
//       final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
//       final idToken = googleUser.authentication.idToken;
//       final authorizationClient = googleUser.authorizationClient;
//       GoogleSignInClientAuthorization? authorization = await authorizationClient
//           .authorizationForScopes(['email', 'profile']);
//       final accessToken = authorization?.accessToken;
//       if (accessToken == null) {
//         final authorization2 = await authorizationClient.authorizationForScopes(
//           ['email', 'profile'],
//         );
//         if (authorization2?.accessToken == null) {
//           throw FirebaseAuthException(code: "error", message: "error");
//         }
//         authorization = authorization2;
//       }
//       final credential = GoogleAuthProvider.credential(
//         accessToken: accessToken,
//         idToken: idToken,
//       );
//       final UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithCredential(credential);
//       final User? user = userCredential.user;
//       if (user != null) {
//         final userDoc = FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid);
//         final docSnapshot = await userDoc.get();
//         if (!docSnapshot.exists) {
//           await userDoc.set({
//             'uid': user.uid,
//             'name': user.displayName ?? '',
//             'email': user.email ?? '',
//             'photoURL': user.photoURL ?? '',
//             'provider': 'google',
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         }
//       }
//       return userCredential;
//     } catch (e) {
//       print('Error: $e');
//       rethrow;
//     }
//   }
//   // Sign out
//   static Future<void> signOut() async {
//     try {
//       await _googleSignIn.signOut();
//       await _auth.signOut();
//     } catch (e) {
//       print('Error signing out: $e');
//       throw e;
//     }
//   }
//   // Get current user
//   static User? getCurrentUser() {
//     return _auth.currentUser;
//   }
// }

  // GOOGLE SIGN IN
  // @override
  // Future<AppUser?> signInWithGoogle() async {
  //   try {
  //     // Get GoogleSignIn instance
  //     final googleSignIn = GoogleSignIn.instance;
      
  //     // Initialize if needed (only once)
  //     await googleSignIn.initialize();
      
  //     // Authenticate the user
  //     final GoogleSignInAccount gUser = await googleSignIn.authenticate();
      
  //     // Get authentication details
  //     final authentication = await gUser.authentication;
      
  //     // Get ID token (required for Firebase)
  //     final String? idToken = authentication.idToken;
      
  //     if (idToken == null) {
  //       throw Exception('Failed to get ID token');
  //     }

  //     // Get access token 
  //     final authClient = gUser.authorizationClient;
  //     final authorization = await authClient.authorizationForScopes(['email']);
  //     final String? accessToken = authorization?.accessToken;

  //     // Create Firebase credential
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: accessToken,
  //       idToken: idToken,
  //     );

  //     // Sign in to Firebase
  //     final UserCredential userCredential =
  //         await firebaseAuth.signInWithCredential(credential);

  //     // Get Firebase user
  //     final firebaseUser = userCredential.user;

  //     if (firebaseUser == null) {
  //       throw Exception('Firebase user is null after sign-in');
  //     }

  //     // Create and return your AppUser
  //     final appUser = AppUser(
  //       uid: firebaseUser.uid,
  //       email: firebaseUser.email ?? '',
  //     );

  //     return appUser;
      
  //   } on GoogleSignInException catch (e) {
  //     print('Google Sign-In Error: $e');
  //     return null;
  //   } on FirebaseAuthException catch (e) {
  //     print('Firebase Auth Error: ${e.code} - ${e.message}');
  //     return null;
  //   } catch (e) {
  //     print('Error during Google sign-in: $e');
  //     return null;
  //   }
  // }