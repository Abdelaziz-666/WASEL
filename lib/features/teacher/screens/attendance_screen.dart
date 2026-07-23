import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/teacher_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TeacherService _teacherService = TeacherService();
  
  String? _selectedStage;
  String? _selectedGroup;
  
  DateTime _selectedDate = DateTime.now();
  
  final List<String> _stages = [
    'الأول الإعدادي', 'الثاني الإعدادي', 'الثالث الإعدادي',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  ];

  Map<String, bool> _attendanceData = {};
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = false;
  bool _isSaving = false;

  Future<void> _fetchStudents() async {
    if (_selectedStage == null || _selectedGroup == null) return;
    
    setState(() => _isLoadingStudents = true);
    
    List<Map<String, dynamic>> students = await _teacherService.getStudentsByGroupStream(_selectedStage!, _selectedGroup!).first;
    
    String dateString = "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}";

    String teacherId = FirebaseAuth.instance.currentUser!.uid;
    var attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('teacherId', isEqualTo: teacherId)
        .where('stage', isEqualTo: _selectedStage)
        .where('group', isEqualTo: _selectedGroup)
        .where('date', isEqualTo: dateString)
        .get();

    Map<String, bool> existingRecords = {};
    if (attendanceSnapshot.docs.isNotEmpty) {
      var data = attendanceSnapshot.docs.first.data() as Map<String, dynamic>;
      if (data.containsKey('records')) {
        Map<String, dynamic> records = data['records'];
        records.forEach((key, value) {
          existingRecords[key] = value == true;
        });
      }
    }

    setState(() {
      _students = students;
      _attendanceData.clear();
      
      for (var student in _students) {
        String studentId = student['id'];
        _attendanceData[studentId] = existingRecords[studentId] ?? false; 
      }
      _isLoadingStudents = false;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B3B5A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (_selectedStage != null && _selectedGroup != null) {
        _fetchStudents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('حضور الحصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1B3B5A).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تاريخ الحصة: ${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A)),
                          ),
                          const Icon(Icons.calendar_month, color: Color(0xFF1B3B5A)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _selectedStage,
                    decoration: _inputDecoration('اختر المرحلة الدراسية'),
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
                        if (groups.isEmpty) {
                          return const Text('لا توجد مجموعات مسجلة لهذه المرحلة', style: TextStyle(color: Colors.red));
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedGroup,
                          decoration: _inputDecoration('اختر المجموعة'),
                          items: groups.map((group) {
                            String groupName = group['groupName'];
                            return DropdownMenuItem(value: groupName, child: Text(groupName));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedGroup = val;
                            });
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
                      ? const Center(child: Text('لا يوجد طلاب معتمدين في هذه المجموعة حتى الآن', style: TextStyle(fontSize: 16, color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            var student = _students[index];
                            String studentId = student['id'];
                            String studentName = student['name'] ?? 'طالب';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: CheckboxListTile(
                                activeColor: const Color(0xFF2B4D7E),
                                title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Text(student['phone'] ?? ''),
                                value: _attendanceData[studentId] ?? false,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _attendanceData[studentId] = value ?? false;
                                  });
                                },
                              ),
                            );
                          },
                        ),
            ),

            if (_students.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () async {
                      setState(() => _isSaving = true);
                      
                      String result = await _teacherService.saveAttendance(
                        stage: _selectedStage!,
                        groupName: _selectedGroup!,
                        date: _selectedDate,
                        attendanceRecords: _attendanceData,
                      );
                      
                      setState(() => _isSaving = false);
                      
                      if (!mounted) return;
                      if (result == "success") {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ غياب الحصة بنجاح'), backgroundColor: Colors.green));
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B4D7E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('حفظ سجل الحضور', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
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