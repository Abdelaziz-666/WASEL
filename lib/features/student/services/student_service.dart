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

  Stream<int> getUnreadNotificationsCount(String teacherId, String stage, String group) {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String targetType = data['targetType'] ?? 'all';
            
            bool isForMe = false;
            if (targetType == 'all') {
              isForMe = true;
            } else if (targetType == 'stage' && data['stage'] == stage) {
              isForMe = true;
            } else if (targetType == 'group' && data['stage'] == stage && data['group'] == group) {
              isForMe = true;
            }

            if (isForMe) {
              List<dynamic> readBy = data['readBy'] ?? [];
              if (!readBy.contains(uid)) {
                count++;
              }
            }
          }
          return count;
        });
  }

  Future<void> markNotificationsAsRead(String teacherId, String stage, String group) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    var snapshot = await _firestore.collection('notifications')
        .where('teacherId', isEqualTo: teacherId)
        .get();
        
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String targetType = data['targetType'] ?? 'all';
            
      bool isForMe = false;
      if (targetType == 'all') {
        isForMe = true;
      } else if (targetType == 'stage' && data['stage'] == stage) {
        isForMe = true;
      } else if (targetType == 'group' && data['stage'] == stage && data['group'] == group) {
        isForMe = true;
      }

      if (isForMe) {
        List<dynamic> readBy = data['readBy'] ?? [];
        if (!readBy.contains(uid)) {
          await doc.reference.update({
            'readBy': FieldValue.arrayUnion([uid])
          });
        }
      }
    }
  }

  Stream<QuerySnapshot> getExamsForTeacher(String teacherId, String stage, String group, int year, int month) {
    return _firestore
        .collection('exams')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: group)
        .snapshots();
  }

  Stream<QuerySnapshot> getAttendanceForTeacher(String teacherId, String stage, String group, int year, int month) {
    return _firestore
        .collection('attendance')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: group)
        .snapshots();
  }

  Stream<QuerySnapshot> getAssignmentsForTeacher(String teacherId, String stage, String group, int year, int month) {
    return _firestore
        .collection('assignments')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: group)
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
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('inquiries')
        .where('studentId', isEqualTo: uid)
        .snapshots();
  }

Future<void> deleteInquiry(String inquiryId) async {
    try {
      await _firestore.collection('inquiries').doc(inquiryId).update({
        'isDeletedByStudent': true,
      });
    } catch (e) {
      print("Error deleting inquiry: $e");
    }
  }

  Stream<int> getAnsweredInquiriesCount() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    
    return _firestore
        .collection('inquiries')
        .where('studentId', isEqualTo: uid)
        .where('status', isEqualTo: 'answered')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markInquiriesAsRead() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    var snapshot = await _firestore.collection('inquiries')
        .where('studentId', isEqualTo: uid)
        .where('status', isEqualTo: 'answered')
        .get();
        
    for (var doc in snapshot.docs) {
      await doc.reference.update({'status': 'read'});
    }
  }

  Stream<QuerySnapshot> getStudentSubscriptions() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
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

  Stream<List<Map<String, dynamic>>> getActiveSubscriptions() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _firestore
        .collection('subscriptions')
        .where('studentId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();
        });
  }

  Stream<QuerySnapshot> getStudentPayments(String teacherId, String stage, String groupName, int year) {
    return _firestore
        .collection('payments')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: stage)
        .where('group', isEqualTo: groupName)
        .where('year', isEqualTo: year)
        .snapshots();
  }
}