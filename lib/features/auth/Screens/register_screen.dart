import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'pending_approval_screen.dart';
import '../../../core/widgets/auth_background_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_dropdown.dart';
import '../../../core/widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fatherPhoneController = TextEditingController();
  final TextEditingController _motherPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedStage;
  String? _selectedTeacherId;
  String? _selectedGroup;

  final List<String> _stages = [
    'الأول الإعدادي', 'الثاني الإعدادي', 'الثالث الإعدادي',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _fatherPhoneController.dispose();
    _motherPhoneController.dispose();
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
            const Text('حساب جديد', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
            const SizedBox(height: 30),
            CustomTextField(controller: _nameController, hintText: 'الاسم الثلاثي', icon: Icons.person),
            const SizedBox(height: 16),
            CustomTextField(controller: _phoneController, hintText: 'رقم هاتف الطالب', icon: Icons.phone, isNumber: true),
            const SizedBox(height: 16),
            CustomTextField(controller: _fatherPhoneController, hintText: 'رقم هاتف الأب', icon: Icons.phone_android, isNumber: true),
            const SizedBox(height: 16),
            CustomTextField(controller: _motherPhoneController, hintText: 'رقم هاتف الأم', icon: Icons.phone_android, isNumber: true),
            const SizedBox(height: 16),
            CustomDropdown(
              hint: 'اختر المرحلة الدراسية',
              value: _selectedStage,
              prefixIcon: Icons.school,
              items: _stages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
              onChanged: (value) => setState(() { _selectedStage = value; _selectedGroup = null; }),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _authService.getTeachers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var teachers = snapshot.data!.docs;
                return CustomDropdown(
                  hint: 'اختر المدرس',
                  value: _selectedTeacherId,
                  prefixIcon: Icons.person_pin,
                  items: teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t['name'] ?? 'بدون اسم'))).toList(),
                  onChanged: (val) => setState(() { _selectedTeacherId = val; _selectedGroup = null; }),
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: (_selectedTeacherId != null && _selectedStage != null)
                  ? _authService.getGroupsByTeacherAndStage(_selectedTeacherId!, _selectedStage!)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                List<DropdownMenuItem<String>> groupItems = [];
                if (snapshot.hasData) {
                  groupItems = snapshot.data!.docs.map((g) => DropdownMenuItem<String>(value: g['groupName'], child: Text(g['groupName']))).toList();
                }
                return CustomDropdown(
                  hint: 'اختر المجموعة',
                  value: _selectedGroup,
                  prefixIcon: Icons.group,
                  items: groupItems,
                  onChanged: _selectedTeacherId != null ? (val) => setState(() => _selectedGroup = val) : null,
                );
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: _passwordController, hintText: 'كلمة المرور', icon: Icons.lock, isPassword: true),
            const SizedBox(height: 32),
            CustomButton(
              text: 'تسجيل',
              isLoading: _isLoading,
              onPressed: () async {
                if (_formKey.currentState!.validate() && _selectedStage != null && _selectedTeacherId != null && _selectedGroup != null) {
                  setState(() => _isLoading = true);
                  String? result = await _authService.registerStudent(
                    name: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    fatherPhone: _fatherPhoneController.text.trim(),
                    motherPhone: _motherPhoneController.text.trim(),
                    stage: _selectedStage!,
                    teacherId: _selectedTeacherId!,
                    group: _selectedGroup!,
                    password: _passwordController.text,
                  );
                  setState(() => _isLoading = false);
                  if (!context.mounted) return;

                  if (result == "success") {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PendingApprovalScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? 'خطأ'), backgroundColor: Colors.red));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أكمل جميع الاختيارات'), backgroundColor: Colors.orange));
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لديك حساب بالفعل؟ تسجيل الدخول', style: TextStyle(color: Color(0xFF2B4D7E), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}