import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingStudents() {
    String teacherId = FirebaseAuth.instance.currentUser!.uid;
    
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('status', isEqualTo: 'pending')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots(); 
  }

  Future<void> approveStudent(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'active',
      });
    } catch (e) {
      print("Error approving student: $e");
    }
  }

  Future<void> rejectStudent(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error rejecting student: $e");
    }
  }

  Future<String> addGroup({required String stage, required String groupName}) async {
    try {
      String teacherId = FirebaseAuth.instance.currentUser!.uid; 

      await _firestore.collection('groups').add({
        'stage': stage,
        'groupName': groupName,
        'teacherId': teacherId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  Stream<QuerySnapshot> getGroups() {
    String teacherId = FirebaseAuth.instance.currentUser!.uid;
    return _firestore
        .collection('groups')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  Stream<QuerySnapshot> getGroupsByStage(String stage) {
    String teacherId = FirebaseAuth.instance.currentUser!.uid;
    return _firestore
        .collection('groups')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: stage)
        .snapshots();
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).delete();
    } catch (e) {
      print("Error deleting group: $e");
    }
  }

  Future<QuerySnapshot> getStudentsByGroup(String stage, String groupName) {
    String teacherId = FirebaseAuth.instance.currentUser!.uid;

    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('status', isEqualTo: 'active')
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: groupName)
        .where('teacherId', isEqualTo: teacherId)
        .get();
  }

  Future<String> saveAttendance({
    required String stage,
    required String groupName,
    required DateTime date,
    required Map<String, bool> attendanceRecords,
  }) async {
    try {
      String dateString = "${date.year}-${date.month}-${date.day}";
      
      await _firestore.collection('attendance').add({
        'stage': stage,
        'group': groupName,
        'date': dateString,
        'records': attendanceRecords, 
        'timestamp': FieldValue.serverTimestamp(),
      });
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> saveExamGrades({
    required String stage,
    required String groupName,
    required String examName,
    required String maxGrade,
    required DateTime date,
    required Map<String, String> gradesRecords,
  }) async {
    try {
      String dateString = "${date.year}-${date.month}-${date.day}";
      
      await _firestore.collection('exams').add({
        'stage': stage,
        'group': groupName,
        'examName': examName,
        'maxGrade': maxGrade,
        'date': dateString,
        'records': gradesRecords, 
        'timestamp': FieldValue.serverTimestamp(),
      });
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> sendNotification({
    required String targetType,
    String? stage,
    String? groupName,
    required String title,
    required String body,
  }) async {
    try {
      String teacherId = FirebaseAuth.instance.currentUser!.uid;

      await _firestore.collection('notifications').add({
        'teacherId': teacherId,
        'targetType': targetType,
        'stage': stage,
        'group': groupName,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return "success";
    } catch (e) {
      return e.toString();
    }
  }
}