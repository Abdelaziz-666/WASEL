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

  Stream<QuerySnapshot> getStudentNotifications(String teacherId) {
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

  Future<String> sendInquiry({
    required String teacherId,
    required String studentName,
    required String question,
  }) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return "error";

      await _firestore.collection('inquiries').add({
        'studentId': uid,
        'studentName': studentName,
        'teacherId': teacherId,
        'question': question,
        'answer': '',
        'status': 'pending',
        'isStarred': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  Stream<QuerySnapshot> getStudentInquiries() {
    String uid = _auth.currentUser!.uid;
    return _firestore
        .collection('inquiries')
        .where('studentId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> deleteInquiry(String inquiryId) async {
    try {
      await _firestore.collection('inquiries').doc(inquiryId).delete();
    } catch (e) {
      print("Error deleting inquiry: $e");
    }
  }

  Stream<QuerySnapshot> getStudentSubscriptions() {
    String? uid = _auth.currentUser?.uid;
    return _firestore
        .collection('subscriptions')
        .where('studentId', isEqualTo: uid)
        .snapshots();
  }

  Future<String> addTeacherSubscription({
    required String teacherId,
    required String teacherName,
    required String stage,
    required String groupName,
  }) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return "error";

      var userDoc = await _firestore.collection('users').doc(uid).get();
      String studentName = userDoc.data()?['name'] ?? 'طالب';
      String studentPhone = userDoc.data()?['phone'] ?? '';

      var check = await _firestore.collection('subscriptions')
          .where('studentId', isEqualTo: uid)
          .where('teacherId', isEqualTo: teacherId)
          .get();
      
      if (check.docs.isNotEmpty) {
        return "أنت مسجل بالفعل مع هذا المدرس!";
      }

      await _firestore.collection('subscriptions').add({
        'studentId': uid,
        'studentName': studentName,
        'studentPhone': studentPhone,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'stage': stage,
        'group': groupName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return "success";
    } catch (e) {
      return "حدث خطأ: $e";
    }
  }

  Stream<QuerySnapshot> getStudentAssignments(String teacherId, String stage, String groupName) {
    return _firestore
        .collection('assignments')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: groupName)
        .snapshots();
  }
}