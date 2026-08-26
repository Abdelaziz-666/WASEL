import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/teacher_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
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
  Map<String, bool> _paymentData = {};
  
  bool _isLoadingStudents = false;
  bool _isSaving = false;

  Future<void> _fetchStudentsAndPayments() async {
    if (_selectedStage == null || _selectedGroup == null) return;
    
    setState(() => _isLoadingStudents = true);
    
    List<Map<String, dynamic>> students = await _teacherService.getStudentsByGroupStream(_selectedStage!, _selectedGroup!).first;
    Map<String, bool> existingPayments = await _teacherService.getPaymentsForMonth(_selectedStage!, _selectedGroup!, _selectedYear, _selectedMonth);

    setState(() {
      _students = students;
      _paymentData.clear();
      
      for (var student in _students) {
        String studentId = student['id'];
        _paymentData[studentId] = existingPayments[studentId] ?? false; 
      }
      _isLoadingStudents = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text(' الاشتراكات ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          onChanged: (val) {
                            setState(() => _selectedYear = val!);
                            _fetchStudentsAndPayments();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          decoration: _inputDecoration('الشهر', Icons.date_range),
                          items: _months.map((m) => DropdownMenuItem(value: m, child: Text('شهر $m'))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedMonth = val!);
                            _fetchStudentsAndPayments();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedStage,
                    decoration: _inputDecoration('المرحلة الدراسية', Icons.school),
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
                        if (groups.isEmpty) return const Text('لا توجد مجموعات', style: TextStyle(color: Colors.red));

                        return DropdownButtonFormField<String>(
                          value: _selectedGroup,
                          decoration: _inputDecoration('المجموعة', Icons.group),
                          items: groups.map((g) {
                            String name = g['groupName'];
                            return DropdownMenuItem(value: name, child: Text(name));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedGroup = val);
                            _fetchStudentsAndPayments();
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
                      ? const Center(child: Text('لا يوجد طلاب', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            var student = _students[index];
                            String id = student['id'];
                            String name = student['name'] ?? 'طالب';
                            bool isPaid = _paymentData[id] == true;

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
                                          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                                          const SizedBox(height: 4),
                                          Text(student['phone'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => setState(() => _paymentData[id] = true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isPaid ? Colors.green : Colors.grey.shade200,
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                            ),
                                            child: Text('دفع', style: TextStyle(color: isPaid ? Colors.white : Colors.black87 , fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => setState(() => _paymentData[id] = false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: !isPaid ? Colors.red.shade400 : Colors.grey.shade200,
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                            ),
                                            child: Text('لم يدفع', style: TextStyle(color: !isPaid ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
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
                      String result = await _teacherService.savePayments(
                        stage: _selectedStage!,
                        groupName: _selectedGroup!,
                        year: _selectedYear,
                        month: _selectedMonth,
                        paymentRecords: _paymentData,
                      );
                      setState(() => _isSaving = false);

                      if (!mounted) return;
                      if (result == "success") {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الاشتراكات بنجاح'), backgroundColor: Colors.green));
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
                        : const Text('حفظ حالة الدفع', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
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