import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// مسارات الشاشات (تأكد إنها مطابقة لأسماء الفولدرات عندك)
import 'features/auth/Screens/login_screen.dart';
import 'features/teacher/screens/teacher_dashboard_screen.dart';
import 'features/student/screens/student_teachers_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Center App',
      // توحيد اتجاه التطبيق لليمين (عربي) في كل الشاشات
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      // توحيد الألوان والستايلات (Global Theme)
      theme: ThemeData(
        fontFamily: 'Cairo', // لو ضايف خط عربي في pubspec.yaml
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B3B5A),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2B4D7E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      // بوابة الدخول الذكية
      home: const AuthGate(), 
    );
  }
}

// ==========================================
// بوابة الدخول (تفحص حالة المستخدم أول ما يفتح)
// ==========================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. لو بيحمل لسه
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. لو مفيش يوزر مسجل دخول (وديه اللوجين)
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // 3. لو في يوزر مسجل دخول، لازم نعرف هو مدرس ولا طالب
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              // الطريقة الآمنة لقراءة البيانات
              Map<String, dynamic> userData = userSnapshot.data!.data() as Map<String, dynamic>;
              String role = userData.containsKey('role') ? userData['role'] : '';
              
              if (role == 'teacher') {
                // المدرس بيروح للداشبورد بتاعته
                return const TeacherDashboardScreen();
              } else if (role == 'student') {
                // الطالب بيروح لشاشة اختيار المدرسين بتوعه
                return const StudentTeachersScreen(); 
              }
            }
            
            // 4. في حالة وجود خطأ في الداتا أو الحساب ممسوح، نرجعه للوجين أمان
            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          },
        );
      },
    );
  }
}