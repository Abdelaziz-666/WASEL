import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'pending_approval_screen.dart';
import '../../../core/widgets/auth_background_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_dropdown.dart';
import '../../../core/widgets/custom_button.dart';

class UpdateRegistrationScreen extends StatefulWidget {
  const UpdateRegistrationScreen({super.key});

  @override
  State<UpdateRegistrationScreen> createState() => _UpdateRegistrationScreenState();
}

class _UpdateRegistrationScreenState extends State<UpdateRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isSaving = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fatherPhoneController = TextEditingController();
  final TextEditingController _motherPhoneController = TextEditingController();

  String? _selectedStage;
  String? _selectedTeacherId;
  String? _selectedGroup;

  final List<String> _stages = [
    'الأول الإعدادي', 'الثاني الإعدادي', 'الثالث الإعدادي',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentStudentData();
  }

  Future<void> _loadCurrentStudentData() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? '';
          _phoneController.text = doc.data()?['phone'] ?? '';
          _fatherPhoneController.text = doc.data()?['fatherPhone'] ?? '';
          _motherPhoneController.text = doc.data()?['motherPhone'] ?? '';
          _selectedStage = doc.data()?['stage'];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _fatherPhoneController.dispose();
    _motherPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1B3B5A))));
    }

    return AuthBackgroundCard(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تحديث البيانات واختيار مدرس', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
            const SizedBox(height: 30),
            CustomTextField(controller: _nameController, hintText: 'الاسم الثلاثي', icon: Icons.person),
            const SizedBox(height: 16),
            CustomTextField(controller: _phoneController, hintText: 'رقم هاتف الطالب', icon: Icons.phone, isNumber: true, isEnabled: false),
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
              onChanged: (value) => setState(() => _selectedStage = value),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _authService.getTeachers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var teachers = snapshot.data!.docs;
                return CustomDropdown(
                  hint: 'اختر المدرس الجديد',
                  value: _selectedTeacherId,
                  prefixIcon: Icons.person_pin,
                  items: teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t['name'] ?? 'بدون اسم'))).toList(),
                  onChanged: (val) => setState(() { _selectedTeacherId = val; _selectedGroup = null; }),
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _selectedTeacherId != null && _selectedStage != null
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
            const SizedBox(height: 32),
            CustomButton(
              text: 'إرسال الطلب للمدرس الجديد',
              isLoading: _isSaving,
              onPressed: () async {
                if (_formKey.currentState!.validate() && _selectedStage != null && _selectedTeacherId != null && _selectedGroup != null) {
                  setState(() => _isSaving = true);
                  String? result = await _authService.updateStudentRejectedProfile(
                    name: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    fatherPhone: _fatherPhoneController.text.trim(),
                    motherPhone: _motherPhoneController.text.trim(),
                    stage: _selectedStage!,
                    teacherId: _selectedTeacherId!,
                    group: _selectedGroup!,
                  );
                  setState(() => _isSaving = false);
                  if (!mounted) return;

                  if (result == "success") {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PendingApprovalScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? 'خطأ'), backgroundColor: Colors.red));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى استكمال البيانات واختيار المدرس والمجموعة'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}