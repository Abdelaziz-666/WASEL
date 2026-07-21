import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_requests_screen.dart';
import 'add_group_screen.dart';
import 'attendance_screen.dart';
import 'exam_grades_screen.dart';
import 'send_notification_screen.dart';
import 'teacher_inquiries_screen.dart';
import 'teacher_assignments_screen.dart';
import '../../auth/Screens/login_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String teacherName = '...';
  bool isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherName();
  }

  Future<void> _fetchTeacherName() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            teacherName = userDoc.get('name');
            isLoadingName = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        teacherName = '';
        isLoadingName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          elevation: 0,
          title: const Text(
            'لوحة تحكم المدرس',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isLoadingName
                  ? const CircularProgressIndicator()
                  : Text(
                      'مرحباً بك يا أستاذ $teacherName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3B5A),
                      ),
                    ),
              const SizedBox(height: 8),
              const Text(
                'اختر القسم الذي تريد إدارته',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildDashboardCard(
                      context,
                      title: 'طلبات الانضمام',
                      icon: Icons.person_add_alt_1,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewRequestsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'إدارة الطلاب',
                      icon: Icons.manage_accounts,
                      onTap: () {},
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'حضور الحصة',
                      icon: Icons.how_to_reg,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AttendanceScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'أداء الواجبات',
                      icon: Icons.assignment_turned_in,
                      onTap: () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TeacherAssignmentsScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'درجات الامتحانات',
                      icon: Icons.grading,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExamGradesScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      title: 'إرسال إشعار',
                      icon: Icons.notification_add,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SendNotificationScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                    context,
                    title: 'الاستفسارات', 
                    icon: Icons.chat_bubble_outline, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TeacherInquiriesScreen()),
                      );
                    }
                  ),
                    _buildDashboardCard(
                      context,
                      title: 'إضافة مجموعة',
                      icon: Icons.group_add,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddGroupScreen(),
                          ),
                        );
                      },
                    ),

                    _buildDashboardCard(
                      context,
                      title: 'إضافة مساعد',
                      icon: Icons.admin_panel_settings,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: const Color(0xFF1B3B5A)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3B5A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}