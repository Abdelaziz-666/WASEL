import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_service.dart';
import '../../auth/services/auth_service.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final StudentService _studentService = StudentService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String? _selectedTeacherId;
  String? _selectedTeacherName;
  String? _selectedStage;
  String? _selectedGroup;
  bool _isSaving = false;

  final List<String> _stages = [
    'الأول الإعدادي', 'الثاني الإعدادي', 'الثالث الإعدادي',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('الانضمام لمدرس جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 60, color: Color(0xFF1B3B5A)),
                    const SizedBox(height: 16),
                    const Text('اختر المدرس والمرحلة لإرسال طلب الانضمام', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 24),

                    StreamBuilder<QuerySnapshot>(
                      stream: _authService.getTeachers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        var teachers = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          value: _selectedTeacherId,
                          decoration: _inputDecoration('اختر المدرس', Icons.person_pin),
                          items: teachers.map((teacher) {
                            return DropdownMenuItem(value: teacher.id, child: Text(teacher['name'] ?? 'بدون اسم'));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTeacherId = val;
                              _selectedTeacherName = teachers.firstWhere((t) => t.id == val)['name'];
                              _selectedGroup = null;
                            });
                          },
                          validator: (val) => val == null ? 'يرجى اختيار المدرس' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedStage,
                      decoration: _inputDecoration('المرحلة الدراسية', Icons.school),
                      items: _stages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedStage = val;
                          _selectedGroup = null;
                        });
                      },
                      validator: (val) => val == null ? 'يرجى اختيار المرحلة' : null,
                    ),
                    const SizedBox(height: 16),

                    StreamBuilder<QuerySnapshot>(
                      stream: (_selectedTeacherId != null && _selectedStage != null)
                          ? _authService.getGroupsByTeacherAndStage(_selectedTeacherId!, _selectedStage!)
                          : const Stream.empty(),
                      builder: (context, snapshot) {
                        List<DropdownMenuItem<String>> groupItems = [];
                        bool hasTeacherAndStage = _selectedTeacherId != null && _selectedStage != null;

                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          groupItems = snapshot.data!.docs.map((g) {
                            String groupName = g['groupName'] ?? '';
                            return DropdownMenuItem<String>(
                              value: groupName,
                              child: Text(groupName),
                            );
                          }).toList();
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedGroup,
                          isExpanded: true,
                          decoration: _inputDecoration('المجموعة', Icons.group),
                          hint: Text(
                            hasTeacherAndStage ? 'اختر المجموعة' : 'اختر المدرس والمرحلة أولاً',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          items: groupItems,
                          onChanged: hasTeacherAndStage ? (val) => setState(() => _selectedGroup = val) : null,
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
                            String result = await _studentService.addTeacherSubscription(
                              teacherId: _selectedTeacherId!,
                              teacherName: _selectedTeacherName!,
                              stage: _selectedStage!,
                              groupName: _selectedGroup!,
                            );
                            setState(() => _isSaving = false);

                            if (!mounted) return;
                            if (result == "success") {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب للمدرس بنجاح!'), backgroundColor: Colors.green));
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B4D7E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('إرسال طلب الانضمام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF0F2F5),
      prefixIcon: Icon(icon, color: const Color(0xFF1B3B5A)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}