import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'pending_approval_screen.dart';
import 'rejected_student_screen.dart';
import '../services/auth_service.dart';
import '../../teacher/screens/teacher_dashboard_screen.dart';
import '../../student/screens/student_teachers_screen.dart';
import '../../../core/widgets/auth_background_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundCard(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // لو حابة تقريب الحوائط
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  // هذا السطر يقوم بإزالة أي تباين في اللون الأبيض ويجعله شفافاً مع الخلفية البيضاء
                  color: Colors.white.withOpacity(0.0),
                  colorBlendMode: BlendMode.dst,
                ),
              ),
            ),
            const Text('تسجيل الدخول', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
            const SizedBox(height: 40),
            CustomTextField(
              controller: _phoneController,
              hintText: 'رقم الهاتف',
              icon: Icons.phone,
              isNumber: true,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              hintText: 'كلمة المرور أو الكود',
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'دخول',
              isLoading: _isLoading,
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isLoading = true);
                  String result = await _authService.loginUser(
                    phone: _phoneController.text.trim(),
                    password: _passwordController.text,
                  );
                  setState(() => _isLoading = false);
                  if (!context.mounted) return;

                  if (result == 'student') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentTeachersScreen()));
                  } else if (result == 'teacher') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()));
                  } else if (result == 'pending') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PendingApprovalScreen()));
                  } else if (result == 'rejected') {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RejectedStudentScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {},
              child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Color(0xFF2B4D7E), fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ليس لديك حساب؟', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('إنشاء حساب جديد', style: TextStyle(color: Color(0xFF2B4D7E), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
