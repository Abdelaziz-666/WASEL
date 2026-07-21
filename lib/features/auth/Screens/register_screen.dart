import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'pending_approval_screen.dart';

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

  bool _isPasswordVisible = false;

  final List<String> _stages = [
    'الأول الإعدادي', 'الثاني الإعدادي', 'الثالث الإعدادي',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  ];
  List<String> _groups = [];

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
                          'حساب جديد',
                          style: TextStyle(
                            fontSize: 28,
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
                          isNumber: true
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

                        _buildDropdown(
                          hint: 'اختر المرحلة الدراسية',
                          value: _selectedStage,
                          items: _stages,
                          onChanged: (value) => setState(() {
                            _selectedStage = value;
                            _selectedGroup = null;
                          }),
                        ),
                        const SizedBox(height: 16),
                        
                        StreamBuilder<QuerySnapshot>(
                          stream: _authService.getTeachers(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Text(
                                'لا يوجد مدرسين متاحين حالياً',
                                style: TextStyle(color: Colors.red),
                              );
                            }
                            var teachers = snapshot.data!.docs;

                            return DropdownButtonFormField<String>(
                              value: _selectedTeacherId,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B3B5A)),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF0F2F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                prefixIcon: const Icon(Icons.person_pin, color: Color(0xFF1B3B5A)),
                              ),
                              hint: const Text('اختر المدرس', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'يرجى اختيار المدرس';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        StreamBuilder<QuerySnapshot>(
                          stream: (_selectedTeacherId != null && _selectedStage != null)
                              ? _authService.getGroupsByTeacherAndStage(
                                  _selectedTeacherId!,
                                  _selectedStage!,
                                )
                              : null,
                          builder: (context, snapshot) {
                            if (_selectedTeacherId == null || _selectedStage == null) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  _selectedTeacherId == null 
                                      ? 'يرجى اختيار المدرس أولاً'
                                      : 'يرجى اختيار المرحلة أولاً',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            if (snapshot?.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot == null || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: const Text(
                                  'لا توجد مجموعات لهذا المدرس في هذه المرحلة',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            var groups = snapshot.data!.docs;

                            return DropdownButtonFormField<String>(
                              value: _selectedGroup,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B3B5A)),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF0F2F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                prefixIcon: const Icon(Icons.group, color: Color(0xFF1B3B5A)),
                              ),
                              hint: const Text('اختر المجموعة', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              items: groups.map((doc) {
                                String groupName = doc['groupName'] ?? 'بدون اسم';
                                return DropdownMenuItem<String>(
                                  value: groupName,
                                  child: Text(groupName),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedGroup = val;
                                });
                              },
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'يرجى اختيار المجموعة';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'كلمة المرور',
                          icon: Icons.lock,
                          isPassword: true,
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                if (_selectedStage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يرجى اختيار المرحلة'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                if (_selectedTeacherId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يرجى اختيار المدرس'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                if (_selectedGroup == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يرجى اختيار المجموعة'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _isLoading = true;
                                });

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

                                setState(() {
                                  _isLoading = false;
                                });

                                if (result == "success") {
                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PendingApprovalScreen(),
                                    ),
                                  );
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result ?? 'حدث خطأ غير معروف'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B4D7E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'تسجيل',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'لديك حساب بالفعل؟ تسجيل الدخول',
                            style: TextStyle(
                              color: Color(0xFF2B4D7E),
                              fontWeight: FontWeight.w600,
                            ),
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
    bool isPassword = false,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (isNumber && value.length < 11) {
          return 'رقم الهاتف غير صحيح';
        }
        if (isPassword && value.length < 6) {
          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF0F2F5),
        prefixIcon: Icon(icon, color: const Color(0xFF1B3B5A)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF1B3B5A),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B3B5A)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF0F2F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'يرجى اختيار عنصر من القائمة';
        }
        return null;
      },
    );
  }
}