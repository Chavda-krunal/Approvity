import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error: ${e.message}");
      return null;
    } catch (e) {
      debugPrint("General Error: $e");
      return null;
    }
  }

  // Register and save to Firestore
  Future<User?> registerWithEmail(String email, String password, String name, String role) async {
    try {
      // 1. Create the user in Firebase Authentication
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        // 2. Prepare the user data map
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': role,
          'department': '', // Empty by default until they complete Setup
          'fcmToken': '',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // 3. Save that data into the 'users' collection in Firestore
        await _firestore.collection('users').doc(user.uid).set(userData);

        // 4. PREVENT AUTO-LOGIN: Immediately sign the user out
        await _auth.signOut();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Register Error: ${e.message}");
      return null;
    } catch (e) {
      debugPrint("General Register Error: $e");
      return null;
    }
  }

  // Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Check if a user is currently logged in
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}