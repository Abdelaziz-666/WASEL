import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getStudentData() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  Stream<QuerySnapshot> getTeacherNotifications(String teacherId) {
    return _firestore
        .collection('notifications')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  Stream<QuerySnapshot> getStudentExams(String stage, String groupName) {
    return _firestore
        .collection('exams')
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: groupName)
        .snapshots();
  }

  Stream<QuerySnapshot> getStudentAttendance(String stage, String groupName) {
    return _firestore
        .collection('attendance')
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: groupName)
        .snapshots();
  }
}