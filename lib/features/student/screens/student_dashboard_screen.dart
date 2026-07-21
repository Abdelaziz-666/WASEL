import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_notifications_screen.dart';
import 'student_grades_screen.dart';
import 'student_attendance_screen.dart';
import '../../auth/Screens/login_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  String studentName = 'جاري التحميل...';
  String studentPhone = '...';
  String studentStage = '...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      
      if (uid != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        
        if (userDoc.exists) {
          setState(() {
            studentName = userDoc.get('name') ?? 'بدون اسم';
            studentPhone = userDoc.get('phone') ?? '';
            studentStage = userDoc.get('stage') ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        studentName = 'خطأ في التحميل';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.menu, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('Menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text('Log Out', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('الصفحة الرئيسية', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B4D7E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF2B4D7E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          child: isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(studentName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('رقم الهاتف: $studentPhone', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('المرحلة: $studentStage', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildDashboardItem(
                    title: 'حضور الحصة', 
                    icon: Icons.calendar_month_outlined, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StudentAttendanceScreen()),
                      );
                    }
                  ),
                  _buildDashboardItem(title: 'أداء الواجبات', icon: Icons.edit_note, onTap: () {}),
                  _buildDashboardItem(title: 'مستوى الامتحانات', icon: Icons.analytics_outlined, onTap: () {}),
                  _buildDashboardItem(
                    title: 'درجاتي', 
                    icon: Icons.workspace_premium_outlined, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StudentGradesScreen()),
                      );
                    }
                  ),
                  _buildDashboardItem(
                    title: 'إشعارات', 
                    icon: Icons.notifications_none, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StudentNotificationsScreen()),
                      );
                    }
                  ),
                  _buildDashboardItem(title: 'اشتراكات', icon: Icons.credit_card, onTap: () {}),
                  
                  const Divider(height: 40, thickness: 1.5, color: Colors.black12),
                  
                  _buildDashboardItem(title: 'الامتحانات التفاعلية', icon: Icons.quiz_outlined, onTap: () {}),
                  _buildDashboardItem(title: 'الاستفسارات', icon: Icons.chat_bubble_outline, onTap: () {}),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardItem({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF1B3B5A), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A)))),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFF0F2F5), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}