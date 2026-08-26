import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/teacher_service.dart';
import 'student_report_screen.dart'; 

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TeacherService _teacherService = TeacherService();
  
  String? _selectedStage;
  String? _selectedGroup;
  
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final List<String> _stages = [
    'الأول الإعدادي', 'الثاني الإعدادي', 'الثالث الإعدادي',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  ];

  final List<int> _years = [2024, 2025, 2026, 2027, 2028];
  final List<int> _months = List.generate(12, (index) => index + 1);

  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = false;

  Future<void> _fetchStudents() async {
    if (_selectedStage == null || _selectedGroup == null) return;
    
    setState(() => _isLoadingStudents = true);
    
    List<Map<String, dynamic>> studentsList = await _teacherService.getStudentsByGroupStream(_selectedStage!, _selectedGroup!).first;
    
    setState(() {
      _students = studentsList;
      _isLoadingStudents = false;
    });
  }

  void _showMoveGroupDialog(String studentId, String studentName) {
    String? targetGroup;
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('نقل الطالب: $studentName'),
          content: StreamBuilder<QuerySnapshot>(
            stream: _teacherService.getGroupsByStage(_selectedStage!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              var groups = snapshot.data!.docs;
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'اختر المجموعة الجديدة',
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: groups.map((g) {
                  String name = g['groupName'];
                  return DropdownMenuItem(value: name, child: Text(name));
                }).toList(),
                onChanged: (val) => targetGroup = val,
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B4D7E)),
              onPressed: () async {
                if (targetGroup == null) return;
                String result = await _teacherService.updateStudentGroup(studentId: studentId, newGroup: targetGroup!);
                if (!mounted) return;
                Navigator.pop(context);
                if (result == "success") {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نقل الطالب بنجاح'), backgroundColor: Colors.green));
                  _fetchStudents();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                }
              },
              child: const Text('تأكيد النقل', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteStudentDialog(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الطالب'),
          content: Text('هل أنت متأكد من إزالة الطالب $studentName من مجموعاتك؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                String result = await _teacherService.removeStudentFromTeacher(studentId);
                if (!mounted) return;
                if (result == "success") {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إزالة الطالب بنجاح'), backgroundColor: Colors.green));
                  _fetchStudents();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                }
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('إدارة الطلاب والتقارير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: _inputDecoration('السنة', Icons.calendar_today),
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                          onChanged: (val) => setState(() => _selectedYear = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          decoration: _inputDecoration('الشهر', Icons.date_range),
                          items: _months.map((m) => DropdownMenuItem(value: m, child: Text('شهر $m'))).toList(),
                          onChanged: (val) => setState(() => _selectedMonth = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedStage,
                    decoration: _inputDecoration('اختر المرحلة الدراسية', Icons.school),
                    items: _stages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStage = val;
                        _selectedGroup = null;
                        _students.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_selectedStage != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: _teacherService.getGroupsByStage(_selectedStage!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        var groups = snapshot.data!.docs;
                        if (groups.isEmpty) return const Text('لا توجد مجموعات مسجلة', style: TextStyle(color: Colors.red));

                        return DropdownButtonFormField<String>(
                          value: _selectedGroup,
                          decoration: _inputDecoration('اختر المجموعة', Icons.group),
                          items: groups.map((g) {
                            String name = g['groupName'];
                            return DropdownMenuItem(value: name, child: Text(name));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedGroup = val);
                            _fetchStudents();
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty && _selectedGroup != null
                      ? const Center(child: Text('لا يوجد طلاب في هذه المجموعة', style: TextStyle(color: Colors.grey, fontSize: 16)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            var student = _students[index];
                            String id = student['id'];
                            String name = student['name'] ?? 'طالب';
                            String phone = student['phone'] ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE3F2FD),
                                  child: Icon(Icons.person, color: Color(0xFF1B3B5A)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B5A))),
                                subtitle: Text(phone, style: const TextStyle(color: Colors.grey)),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'report') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StudentReportScreen(
                                            studentId: id,
                                            studentName: name,
                                            stage: _selectedStage!,
                                            groupName: _selectedGroup!,
                                            year: _selectedYear,
                                            month: _selectedMonth,
                                          ),
                                        ),
                                      );
                                    } else if (value == 'move') {
                                      _showMoveGroupDialog(id, name);
                                    } else if (value == 'delete') {
                                      _showDeleteStudentDialog(id, name);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'report', child: Text('عرض التقرير')),
                                    const PopupMenuItem(value: 'move', child: Text('نقل لمجموعة أخرى')),
                                    const PopupMenuItem(value: 'delete', child: Text('إزالة الطالب', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudentReportScreen(
                                        studentId: id,
                                        studentName: name,
                                        stage: _selectedStage!,
                                        groupName: _selectedGroup!,
                                        year: _selectedYear,
                                        month: _selectedMonth,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}