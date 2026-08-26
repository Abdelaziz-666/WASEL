import 'package:flutter/material.dart';
import '../../auth/Screens/login_screen.dart';
import '../../../core/widgets/auth_background_card.dart';
import '../../../core/widgets/custom_button.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_top_rounded, size: 60, color: Color(0xFF1B3B5A)),
          ),
          const SizedBox(height: 24),
          const Text(
            'طلبك قيد المراجعة',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A)),
          ),
          const SizedBox(height: 16),
          const Text(
            'تم إرسال بياناتك بنجاح إلى المختصين.\nيرجى الانتظار حتى يتم مراجعة طلبك وتفعيل حسابك لتتمكن من تسجيل الدخول.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
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