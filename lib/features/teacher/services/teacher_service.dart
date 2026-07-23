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

  Future<String> rejectStudent(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      var subscriptions = await _firestore
          .collection('subscriptions')
          .where('studentId', isEqualTo: uid)
          .get();
      
      for (var doc in subscriptions.docs) {
        await _firestore.collection('subscriptions').doc(doc.id).delete();
      }
      
      return "success";
    } catch (e) {
      return "حدث خطأ: $e";
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

  Stream<List<Map<String, dynamic>>> getStudentsByGroupStream(String stage, String groupName) {
    String teacherId = FirebaseAuth.instance.currentUser!.uid;
    
    return _firestore
        .collection('subscriptions')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: groupName)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> students = [];
          
          for (var subDoc in snapshot.docs) {
            String studentId = subDoc['studentId'];
            String studentName = subDoc['studentName'] ?? 'طالب';
            String studentPhone = subDoc['studentPhone'] ?? '';
            
            var userDoc = await _firestore.collection('users').doc(studentId).get();
            Map<String, dynamic> studentData = {
              'id': studentId,
              'name': studentName,
              'phone': studentPhone,
              'subscriptionId': subDoc.id,
            };
            
            if (userDoc.exists) {
              var userData = userDoc.data() as Map<String, dynamic>;
              studentData.addAll({
                'fatherPhone': userData['fatherPhone'] ?? '',
                'motherPhone': userData['motherPhone'] ?? '',
                'status': userData['status'] ?? 'active',
              });
            }
            
            students.add(studentData);
          }
          
          return students;
        });
  }

  Future<String> saveAttendance({
    required String stage,
    required String groupName,
    required DateTime date,
    required Map<String, bool> attendanceRecords,
  }) async {
    try {
      String dateString = "${date.year}-${date.month}-${date.day}";
      String teacherId = FirebaseAuth.instance.currentUser!.uid;
      
      await _firestore.collection('attendance').add({
        'teacherId': teacherId,
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
      String teacherId = FirebaseAuth.instance.currentUser!.uid;
      
      await _firestore.collection('exams').add({
        'teacherId': teacherId,
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

  Stream<QuerySnapshot> getPendingRequests() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    return _firestore
        .collection('subscriptions')
        .where('teacherId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<String> approveRequest(String subscriptionId) async {
    try {
      DocumentSnapshot subDoc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
      
      if (subDoc.exists) {
        String studentId = subDoc.get('studentId');

        await _firestore.collection('subscriptions').doc(subscriptionId).update({
          'status': 'approved',
        });

        await _firestore.collection('users').doc(studentId).update({
          'status': 'active',
        });
      }

      return "success";
    } catch (e) {
      return "حدث خطأ: $e";
    }
  }

  Stream<QuerySnapshot> getTeacherInquiries() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    return _firestore
        .collection('inquiries')
        .where('teacherId', isEqualTo: uid)
        .snapshots();
  }

  Future<String> answerInquiry(String inquiryId, String answer) async {
    try {
      await _firestore.collection('inquiries').doc(inquiryId).update({
        'answer': answer,
        'status': 'answered',
      });
      return "success";
    } catch (e) {
      return "حدث خطأ: $e";
    }
  }

  Future<String> saveAssignments({
    required String stage,
    required String groupName,
    required DateTime date,
    required Map<String, String> assignmentRecords,
  }) async {
    try {
      String? teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) return "error";

      String dateString = "${date.year}-${date.month}-${date.day}";

      var existing = await _firestore
          .collection('assignments')
          .where('teacherId', isEqualTo: teacherId)
          .where('stage', isEqualTo: stage)
          .where('group', isEqualTo: groupName)
          .where('date', isEqualTo: dateString)
          .get();

      if (existing.docs.isNotEmpty) {
        await _firestore.collection('assignments').doc(existing.docs.first.id).update({
          'records': assignmentRecords,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('assignments').add({
          'teacherId': teacherId,
          'stage': stage,
          'group': groupName,
          'date': dateString,
          'records': assignmentRecords,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      return "success";
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, bool>> getAttendanceForDate(String stage, String groupName, DateTime date) async {
    try {
      String dateString = "${date.year}-${date.month}-${date.day}";
      String teacherId = FirebaseAuth.instance.currentUser!.uid;
      
      var snapshot = await _firestore
          .collection('attendance')
          .where('teacherId', isEqualTo: teacherId)
          .where('stage', isEqualTo: stage)
          .where('group', isEqualTo: groupName)
          .where('date', isEqualTo: dateString)
          .get();

      if (snapshot.docs.isEmpty) return {};

      var data = snapshot.docs.first.data();
      Map<String, dynamic> records = data['records'] ?? {};
      Map<String, bool> attendanceMap = {};
      
      records.forEach((key, value) {
        attendanceMap[key] = value == true;
      });

      return attendanceMap;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, String>> getExamGradesForDate(String stage, String groupName, String examName, DateTime date) async {
    try {
      String dateString = "${date.year}-${date.month}-${date.day}";
      String teacherId = FirebaseAuth.instance.currentUser!.uid;
      
      var snapshot = await _firestore
          .collection('exams')
          .where('teacherId', isEqualTo: teacherId)
          .where('stage', isEqualTo: stage)
          .where('group', isEqualTo: groupName)
          .where('examName', isEqualTo: examName)
          .where('date', isEqualTo: dateString)
          .get();

      if (snapshot.docs.isEmpty) return {};

      var data = snapshot.docs.first.data();
      Map<String, dynamic> records = data['records'] ?? {};
      Map<String, String> gradesMap = {};
      
      records.forEach((key, value) {
        gradesMap[key] = value.toString();
      });

      return gradesMap;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, String>> getAssignmentsForDate(String stage, String groupName, DateTime date) async {
    try {
      String dateString = "${date.year}-${date.month}-${date.day}";
      String teacherId = FirebaseAuth.instance.currentUser!.uid;
      
      var snapshot = await _firestore
          .collection('assignments')
          .where('teacherId', isEqualTo: teacherId)
          .where('stage', isEqualTo: stage)
          .where('group', isEqualTo: groupName)
          .where('date', isEqualTo: dateString)
          .get();

      if (snapshot.docs.isEmpty) return {};

      var data = snapshot.docs.first.data();
      Map<String, dynamic> records = data['records'] ?? {};
      Map<String, String> assignmentsMap = {};
      
      records.forEach((key, value) {
        assignmentsMap[key] = value.toString();
      });

      return assignmentsMap;
    } catch (e) {
      return {};
    }
  }
}