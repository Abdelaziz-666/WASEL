import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/student_service.dart';

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  final StudentService _studentService = StudentService();
  final String _studentId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    var data = await _studentService.getStudentData();
    if (mounted) {
      setState(() {
        _studentData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B3B5A))),
      );
    }

    if (_studentData == null) {
      return const Scaffold(
        body: Center(child: Text('حدث خطأ في جلب البيانات')),
      );
    }

    String studentStage = _studentData!['stage'] ?? '';
    String studentGroup = _studentData!['group'] ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('درجاتي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _studentService.getStudentExams(studentStage, studentGroup),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            var allExams = snapshot.data!.docs;
            
            allExams.sort((a, b) {
              try {
                Timestamp timeA = a.get('timestamp');
                Timestamp timeB = b.get('timestamp');
                return timeB.compareTo(timeA);
              } catch (e) {
                return 0;
              }
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allExams.length,
              itemBuilder: (context, index) {
                var exam = allExams[index];
                
                String examName = exam['examName'] ?? 'امتحان';
                String maxGrade = exam['maxGrade'] ?? '100';
                String examDate = exam['date'] ?? '';
                
                Map<String, dynamic> records = exam['records'] ?? {};
                String myGrade = records[_studentId] ?? 'غائب';
                
                Color gradeColor = (myGrade == 'غائب' || myGrade.isEmpty) ? Colors.red : const Color(0xFF2B4D7E);
                if (myGrade.isEmpty) myGrade = 'غائب';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(examName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.date_range, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(examDate, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1B3B5A).withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                myGrade,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: gradeColor),
                              ),
                              Container(height: 1, width: 40, color: Colors.grey.withOpacity(0.5), margin: const EdgeInsets.symmetric(vertical: 4)),
                              Text(
                                maxGrade,
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.format_list_bulleted, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('لم يتم رصد درجات لك حتى الآن', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}