import 'package:flutter/material.dart';
import '../services/teacher_service.dart';

class StudentReportScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String stage;
  final String groupName;
  final int year;
  final int month;

  const StudentReportScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.stage,
    required this.groupName,
    required this.year,
    required this.month,
  });

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  final TeacherService _teacherService = TeacherService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reportData = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    var fullList = await _teacherService.getStudentFullReport(
      stage: widget.stage,
      groupName: widget.groupName,
      studentId: widget.studentId,
    );

    List<Map<String, dynamic>> filteredList = [];
    for (var item in fullList) {
      try {
        String dateString = item['date'];
        List<String> parts = dateString.split('-');
        int itemYear = int.parse(parts[0]);
        int itemMonth = int.parse(parts[1]);

        if (itemYear == widget.year && itemMonth == widget.month) {
          filteredList.add(item);
        }
      } catch (e) {
      }
    }

    if (mounted) {
      setState(() {
        _reportData = filteredList;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      List<String> parts = dateString.split('-');
      DateTime dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      List<String> days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      String dayName = days[dt.weekday - 1];
      return "$dayName\n${parts[1]}-${parts[2]}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: Text('تقرير ${widget.studentName}'),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: const Color(0xFF1B3B5A),
                onRefresh: _fetchReportData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تقرير شهر ${widget.month} لسنة ${widget.year}:',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.studentName,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2FA4D9)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'المجموعة: ${widget.groupName}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      if (_reportData.isEmpty)
                        const Center(child: Text('لا توجد بيانات لهذا الطالب في هذا الشهر', style: TextStyle(color: Colors.grey, fontSize: 16)))
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Table(
                            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                            columnWidths: const {
                              0: FlexColumnWidth(1.2), 
                              1: FlexColumnWidth(1.0), 
                              2: FlexColumnWidth(1.0), 
                              3: FlexColumnWidth(1.0), 
                            },
                            children: [
                              TableRow(
                                decoration: const BoxDecoration(color: Color(0xFF4A6572)),
                                children: [
                                  _buildHeaderCell('اليوم والتاريخ'),
                                  _buildHeaderCell('الحضور'),
                                  _buildHeaderCell('الواجب'),
                                  _buildHeaderCell('الدرجة'),
                                ],
                              ),
                              for (var row in _reportData)
                                TableRow(
                                  children: [
                                    _buildDataCell(_formatDate(row['date']), isBlueText: true),
                                    _buildAttendanceCell(row['attendance']),
                                    _buildDataCell(row['assignment'] ?? '-'),
                                    _buildDataCell(row['exam'] ?? '-', isBold: true),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isBlueText = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isBlueText ? const Color(0xFF4A6572) : Colors.black87,
          fontWeight: isBold || isBlueText ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildAttendanceCell(bool? isAttended) {
    if (isAttended == null) return _buildDataCell('-');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: isAttended
            ? const Icon(Icons.check, color: Colors.green, size: 24)
            : const Icon(Icons.close, color: Colors.red, size: 24),
      ),
    );
  }
}