import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/student_service.dart';
import 'add_teacher_screen.dart';
import 'student_dashboard_screen.dart';
import '../../auth/Screens/login_screen.dart';

class StudentTeachersScreen extends StatefulWidget {
  const StudentTeachersScreen({super.key});

  @override
  State<StudentTeachersScreen> createState() => _StudentTeachersScreenState();
}

class _StudentTeachersScreenState extends State<StudentTeachersScreen> {
  final StudentService _studentService = StudentService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text(
            'مدرسيني',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _studentService.getStudentSubscriptions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 100,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لم تنضم لأي مدرس حتى الآن',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTeacherScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'انضم لمدرس الآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B4D7E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            var subscriptions = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                var sub = subscriptions[index];
                String teacherName = sub['teacherName'] ?? 'مدرس';
                String stage = sub['stage'] ?? '';
                String status = sub['status'] ?? 'pending';
                bool isApproved = status == 'approved';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE3F2FD),
                      radius: 30,
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF1B3B5A),
                        size: 30,
                      ),
                    ),
                    title: Text(
                      teacherName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3B5A),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(stage, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isApproved
                                ? 'تمت الموافقة (اضغط للدخول)'
                                : 'قيد المراجعة',
                            style: TextStyle(
                              color: isApproved ? Colors.green : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: isApproved ? () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => StudentDashboardScreen(
                            teacherId: sub['teacherId'],
                            teacherName: teacherName,
                            stage: stage,
                            groupName: sub['group'],
                          ),
                        ),
                      );
                    } : null,
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTeacherScreen()),
            );
          },
          backgroundColor: const Color(0xFF1B3B5A),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'إضافة مدرس',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}