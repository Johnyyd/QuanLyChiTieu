import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quanlychitieu/core/services/sql_server_helper.dart';

final authProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      if (user != null) {
        _syncUserToSql(user).catchError((e) => print('Lỗi khi sync user ở authStateChanges: \$e'));
      }
      return user;
    });
  }

  Future<void> _syncUserToSql(User user, {String? displayNameOverride}) async {
    final name = displayNameOverride ?? user.displayName ?? 'Người dùng';
    final email = user.email ?? '';
    
    // Đồng bộ user qua SQL Server để đảm bảo các khóa ngoại liên kết (Expenses, Groups...) hoạt động đúng.
    // Lệnh này kiểm tra nếu chưa có thì INSERT, có rồi thì UPDATE
    final query = '''
      IF NOT EXISTS (SELECT 1 FROM Users WHERE Id = @id)
      BEGIN
        INSERT INTO Users (Id, DisplayName, Email, PasswordHash)
        VALUES (@id, @name, @email, '');
      END
      ELSE
      BEGIN
        UPDATE Users SET DisplayName = @name, Email = @email WHERE Id = @id;
      END
    ''';
    
    try {
      await SqlServerHelper.instance.executeWriteWithParams(query, {
        'id': user.uid,
        'name': name,
        'email': email,
      });
    } catch (e) {
      print('Error syncing user to SQL Server: $e');
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await _syncUserToSql(credential.user!);
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmailPassword(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore (Optional if moving entirely to SQL, but we keep it for hybrid)
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await _syncUserToSql(userCredential.user!, displayNameOverride: name);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final name = user.displayName ?? googleUser.displayName ?? 'Người dùng';
        
        // Save to users collection to display the name throughout the app
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? googleUser.email,
          'displayName': name,
        }, SetOptions(merge: true));
        
        await _syncUserToSql(user, displayNameOverride: name);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
