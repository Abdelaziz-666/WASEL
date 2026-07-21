import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'pending_approval_screen.dart';

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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B3B5A))),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE3F2FD), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'تحديث البيانات واختيار مدرس',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3B5A),
                          ),
                        ),
                        const SizedBox(height: 30),

                        _buildTextField(
                          controller: _nameController, 
                          hintText: 'الاسم الثلاثي', 
                          icon: Icons.person
                        ),
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _phoneController, 
                          hintText: 'رقم هاتف الطالب', 
                          icon: Icons.phone, 
                          isNumber: true,
                          isEnabled: false,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _fatherPhoneController, 
                          hintText: 'رقم هاتف الأب', 
                          icon: Icons.phone_android, 
                          isNumber: true
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _motherPhoneController, 
                          hintText: 'رقم هاتف الأم', 
                          icon: Icons.phone_android, 
                          isNumber: true
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _selectedStage,
                          isExpanded: true,
                          decoration: _inputDecoration('اختر المرحلة الدراسية'),
                          items: _stages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                          onChanged: (value) => setState(() => _selectedStage = value),
                          validator: (val) => val == null ? 'يرجى اختيار المرحلة الدراسية' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        StreamBuilder<QuerySnapshot>(
                          stream: _authService.getTeachers(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            var teachers = snapshot.data!.docs;

                            return DropdownButtonFormField<String>(
                              value: _selectedTeacherId,
                              isExpanded: true,
                              decoration: _inputDecoration('اختر المدرس الجديد'),
                              items: teachers.map((teacher) {
                                return DropdownMenuItem<String>(
                                  value: teacher.id,
                                  child: Text(teacher['name'] ?? 'بدون اسم'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedTeacherId = val;
                                  _selectedGroup = null;
                                });
                              },
                              validator: (val) => val == null ? 'يرجى اختيار المدرس' : null,
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
                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              groupItems = snapshot.data!.docs.map((g) {
                                String groupName = g['groupName'] ?? '';
                                return DropdownMenuItem<String>(value: groupName, child: Text(groupName));
                              }).toList();
                            }

                            return DropdownButtonFormField<String>(
                              value: _selectedGroup,
                              isExpanded: true,
                              decoration: _inputDecoration('اختر المجموعة'),
                              hint: const Text('اختر المجموعة', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              items: groupItems,
                              onChanged: _selectedTeacherId != null ? (val) => setState(() => _selectedGroup = val) : null,
                              validator: (val) => val == null ? 'يرجى اختيار المجموعة' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : () async {
                              if (_formKey.currentState!.validate()) {
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
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PendingApprovalScreen()),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result ?? 'حدث خطأ'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B4D7E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('إرسال الطلب للمدرس الجديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isNumber = false,
    bool isEnabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: isEnabled,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: isEnabled ? const Color(0xFFF0F2F5) : Colors.grey.shade200,
        prefixIcon: Icon(icon, color: const Color(0xFF1B3B5A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF0F2F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }
}