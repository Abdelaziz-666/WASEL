import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// تعديل المسارات الصحيحة بناءً على مكان ملف auth_gate.dart الحالي
import 'login_screen.dart';
import '../../teacher/screens/teacher_dashboard_screen.dart';
import '../../student/screens/student_teachers_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return LoginScreen(); // بدون const لتجنب الخطأ
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              Map<String, dynamic> userData =
              userSnapshot.data!.data() as Map<String, dynamic>;
              String role = userData.containsKey('role') ? userData['role'] : '';

              if (role == 'teacher') {
                return TeacherDashboardScreen(); // بدون const
              } else if (role == 'student') {
                return StudentTeachersScreen(); // بدون const
              }
            }

            FirebaseAuth.instance.signOut();
            return LoginScreen(); // بدون const
          },
        );
      },
    );
  }
}
