import 'package:flutter/material.dart';
import 'update_registration_screen.dart';
import 'login_screen.dart';
import '../../../core/widgets/auth_background_card.dart';
import '../../../core/widgets/custom_button.dart';

class RejectedStudentScreen extends StatelessWidget {
  const RejectedStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.cancel_outlined, size: 60, color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          const Text(
            'نعتذر منك، تم رفض الطلب',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'للأسف تم رفض طلب انضمامك من قِبل المدرس الحالي.\nيمكنك تعديل بياناتك واختيار مدرس آخر للمتابعة.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'تعديل البيانات واختيار مدرس جديد',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UpdateRegistrationScreen()));
            },
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'العودة لتسجيل الدخول',
            isOutlined: true,
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
    );
  }
}