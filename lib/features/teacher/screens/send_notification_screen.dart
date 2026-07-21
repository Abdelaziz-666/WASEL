import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/teacher_service.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TeacherService _teacherService = TeacherService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String _selectedTarget = 'الكل';
  String? _selectedStage;
  String? _selectedGroup;
  bool _isLoading = false;

  final List<String> _targetOptions = ['الكل', 'مرحلة معينة', 'مجموعة معينة'];
  final List<String> _stages = [
    'الأول الإعدادي', 'الثاني الإعدادي', 'الثالث الإعدادي',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('إرسال إشعار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('لمن تريد إرسال الإشعار؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedTarget,
                    decoration: _inputDecoration('اختر المستهدف'),
                    items: _targetOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTarget = val!;
                        _selectedStage = null;
                        _selectedGroup = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_selectedTarget != 'الكل') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedStage,
                      decoration: _inputDecoration('اختر المرحلة الدراسية'),
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
                  ],

                  if (_selectedTarget == 'مجموعة معينة' && _selectedStage != null) ...[
                    StreamBuilder<QuerySnapshot>(
                      stream: _teacherService.getGroupsByStage(_selectedStage!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        var groups = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          value: _selectedGroup,
                          decoration: _inputDecoration('اختر المجموعة'),
                          items: groups.map((group) {
                            return DropdownMenuItem(value: group['groupName'].toString(), child: Text(group['groupName']));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedGroup = val),
                          validator: (val) => val == null ? 'يرجى اختيار المجموعة' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(thickness: 1.5),
                  const SizedBox(height: 16),

                  const Text('محتوى الإشعار', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('عنوان الإشعار (مثال: تأجيل حصة)'),
                    validator: (val) => val!.isEmpty ? 'يرجى كتابة العنوان' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 4,
                    decoration: _inputDecoration('التفاصيل...'),
                    validator: (val) => val!.isEmpty ? 'يرجى كتابة التفاصيل' : null,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);

                          String targetType = _selectedTarget == 'الكل' ? 'all' : (_selectedTarget == 'مرحلة معينة' ? 'stage' : 'group');

                          String result = await _teacherService.sendNotification(
                            targetType: targetType,
                            stage: _selectedStage,
                            groupName: _selectedGroup,
                            title: _titleController.text,
                            body: _bodyController.text,
                          );

                          setState(() => _isLoading = false);

                          if (!mounted) return;
                          if (result == "success") {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الإشعار بنجاح'), backgroundColor: Colors.green));
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
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('إرسال الإشعار', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF0F2F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}