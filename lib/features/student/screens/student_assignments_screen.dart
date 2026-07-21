import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/student_service.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  final String teacherId;
  final String stage;
  final String groupName;

  const StudentAssignmentsScreen({
    super.key, 
    required this.teacherId, 
    required this.stage, 
    required this.groupName,
  });

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  final StudentService _studentService = StudentService();
  final String _studentId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('متابعة الواجبات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _studentService.getStudentAssignments(widget.teacherId, widget.stage, widget.groupName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد واجبات مسجلة حتى الآن', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            var assignments = snapshot.data!.docs;
            assignments.sort((a, b) {
              try {
                Timestamp timeA = a.get('timestamp');
                Timestamp timeB = b.get('timestamp');
                return timeB.compareTo(timeA);
              } catch (e) {
                return 0;
              }
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                var assignment = assignments[index];
                String dateString = assignment['date'] ?? 'تاريخ غير محدد';
                Map<String, dynamic> records = assignment['records'] ?? {};
                
                String status = records[_studentId] ?? 'لم يؤدى';
                bool isDone = status == 'أدى';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.menu_book, color: Color(0xFF1B3B5A)),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('واجب حصة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                                const SizedBox(height: 4),
                                Text(dateString, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDone ? Colors.green : Colors.red, width: 1),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDone ? Colors.green : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}