import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerStudent({
    required String name,
    required String phone,
    required String fatherPhone,
    required String motherPhone,
    required String stage,
    required String teacherId,
    required String group,
    required String password,
  }) async {
    try {
      String fakeEmail = "$phone@centerapp.com";

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      String studentId = userCredential.user!.uid;

      await _firestore.collection('users').doc(studentId).set({
        'name': name,
        'phone': phone,
        'fatherPhone': fatherPhone,
        'motherPhone': motherPhone,
        'role': 'student',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      DocumentSnapshot teacherDoc = await _firestore.collection('users').doc(teacherId).get();
      String teacherName = teacherDoc.exists ? (teacherDoc.get('name') ?? 'مدرس') : 'مدرس';

      await _firestore.collection('subscriptions').add({
        'studentId': studentId,
        'studentName': name,
        'studentPhone': phone,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'stage': stage,
        'group': group,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'هذا الرقم مسجل بالفعل';
      }
      return 'حدث خطأ: ${e.code}';
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }
  
  Stream<QuerySnapshot> getTeachers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots();
  }

  Future<String> loginUser({
    required String phone,
    required String password,
  }) async {
    try {
      String fakeEmail = "$phone@centerapp.com";

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return "بيانات المستخدم غير موجودة في قاعدة البيانات";
      }

      String role = userDoc.get('role');
      String status = userDoc.get('status');

      if (role == 'student') {
        if (status == 'pending') {
          return 'pending';
        } else if (status == 'suspended') {
          return 'suspended';
        } else if (status == 'rejected') {
          return 'rejected';
        }
      }

      return role;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || 
          e.code == 'wrong-password' || 
          e.code == 'invalid-credential') {
        return 'رقم الهاتف أو كلمة المرور غير صحيحة';
      }
      return 'حدث خطأ: ${e.code}';
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Stream<QuerySnapshot> getGroupsByTeacherAndStage(String teacherId, String stage) {
    return _firestore
        .collection('groups')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: stage)
        .snapshots();
  }

  Future<String?> updateStudentRejectedProfile({
    required String name,
    required String phone,
    required String fatherPhone,
    required String motherPhone,
    required String stage,
    required String teacherId,
    required String group,
  }) async {
    try {
      String? studentId = _auth.currentUser?.uid;
      if (studentId == null) return "خطأ في معرف المستخدم";

      await _firestore.collection('users').doc(studentId).update({
        'name': name,
        'phone': phone,
        'fatherPhone': fatherPhone,
        'motherPhone': motherPhone,
        'status': 'pending',
      });

      DocumentSnapshot teacherDoc = await _firestore.collection('users').doc(teacherId).get();
      String teacherName = teacherDoc.exists ? (teacherDoc.get('name') ?? 'مدرس') : 'مدرس';

      await _firestore.collection('subscriptions').add({
        'studentId': studentId,
        'studentName': name,
        'studentPhone': phone,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'stage': stage,
        'group': group,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return "success";
    } catch (e) {
      return "حدث خطأ: $e";
    }
  }







}