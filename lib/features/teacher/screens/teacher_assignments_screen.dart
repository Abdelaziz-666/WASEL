import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/teacher_service.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  final TeacherService _teacherService = TeacherService();
  
  String? _selectedStage;
  String? _selectedGroup;
  DateTime _selectedDate = DateTime.now();

  final List<String> _stages = [
    'الأول الإعدادي', 'الثاني الإعدادي', 'الثالث الإعدادي',
    'الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي'
  ];

  List<DocumentSnapshot> _students = [];
  Map<String, String> _assignmentData = {};
  Map<String, bool> _attendanceMap = {};
  
  bool _isLoadingStudents = false;
  bool _isSaving = false;

  Future<void> _fetchStudentsAndData() async {
    if (_selectedStage == null || _selectedGroup == null) return;
    
    setState(() => _isLoadingStudents = true);
    
    var studentsSnapshot = await _teacherService.getStudentsByGroup(_selectedStage!, _selectedGroup!);
    
    Map<String, bool> attendance = await _teacherService.getAttendanceForDate(_selectedStage!, _selectedGroup!, _selectedDate);

    String dateString = "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}";
    var assignmentSnapshot = await FirebaseFirestore.instance
        .collection('assignments')
        .where('stage', isEqualTo: _selectedStage)
        .where('group', isEqualTo: _selectedGroup)
        .where('date', isEqualTo: dateString)
        .get();

    Map<String, String> existingRecords = {};
    if (assignmentSnapshot.docs.isNotEmpty) {
      var data = assignmentSnapshot.docs.first.data() as Map<String, dynamic>;
      if (data.containsKey('records')) {
        Map<String, dynamic> recs = data['records'];
        recs.forEach((key, value) {
          existingRecords[key] = value.toString();
        });
      }
    }

    setState(() {
      _students = studentsSnapshot.docs;
      _attendanceMap = attendance;
      _assignmentData.clear();
      
      for (var student in _students) {
        _assignmentData[student.id] = existingRecords[student.id] ?? 'لم يؤدى';
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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      if (_selectedStage != null && _selectedGroup != null) {
        _fetchStudentsAndData();
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
          title: const Text('متابعة الواجبات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                            'تاريخ الواجب: ${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
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
                        if (groups.isEmpty) return const Text('لا توجد مجموعات مسجلة لهذه المرحلة', style: TextStyle(color: Colors.red));

                        return DropdownButtonFormField<String>(
                          value: _selectedGroup,
                          decoration: _inputDecoration('اختر المجموعة'),
                          items: groups.map((g) {
                            String name = g['groupName'];
                            return DropdownMenuItem(value: name, child: Text(name));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedGroup = val);
                            _fetchStudentsAndData();
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
                            String id = student.id;
                            String name = student['name'];
                            
                            bool isAbsent = _attendanceMap[id] == false;
                            String currentStatus = _assignmentData[id] ?? 'لم يؤدى';
                            bool isDone = currentStatus == 'أدى';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                                              if (isAbsent) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                                  child: const Text('غايب في الحصة', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ]
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(student['phone'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() => _assignmentData[id] = 'أدى');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isDone ? Colors.green : Colors.grey.shade200,
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                            ),
                                            child: Text('أدى', style: TextStyle(color: isDone ? Colors.white : Colors.black87 , fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() => _assignmentData[id] = 'لم يؤدى');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: !isDone ? Colors.red.shade400 : Colors.grey.shade200,
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                            ),
                                            child: Text('لم يؤدى', style: TextStyle(color: !isDone ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            if (_students.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () async {
                      setState(() => _isSaving = true);
                      String result = await _teacherService.saveAssignments(
                        stage: _selectedStage!,
                        groupName: _selectedGroup!,
                        date: _selectedDate,
                        assignmentRecords: _assignmentData,
                      );
                      setState(() => _isSaving = false);

                      if (!mounted) return;
                      if (result == "success") {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الواجبات بنجاح'), backgroundColor: Colors.green));
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
                        : const Text('حفظ حالة الواجبات', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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