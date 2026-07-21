import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_service.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  final StudentService _studentService = StudentService();
  
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
        body: Center(child: Text('حدث خطأ في جلب بيانات الطالب')),
      );
    }

    String teacherId = _studentData!['teacherId'] ?? '';
    String studentStage = _studentData!['stage'] ?? '';
    String studentGroup = _studentData!['group'] ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('الإشعارات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _studentService.getTeacherNotifications(teacherId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            var allNotifications = snapshot.data!.docs;
            var filteredNotifications = allNotifications.where((doc) {
              try {
                String targetType = doc.get('targetType');
                if (targetType == 'all') return true;
                if (targetType == 'stage' && doc.get('stage') == studentStage) return true;
                if (targetType == 'group' && doc.get('group') == studentGroup) return true;
                return false;
              } catch (e) {
                return false;
              }
            }).toList();

            filteredNotifications.sort((a, b) {
              try {
                Timestamp timeA = a.get('timestamp');
                Timestamp timeB = b.get('timestamp');
                return timeB.compareTo(timeA);
              } catch (e) {
                return 0;
              }
            });

            if (filteredNotifications.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                var notification = filteredNotifications[index];
                String title = notification['title'] ?? 'إشعار جديد';
                String body = notification['body'] ?? '';
                
                Timestamp? timestamp = notification['timestamp'];
                String timeString = '';
                if (timestamp != null) {
                  DateTime date = timestamp.toDate();
                  timeString = "${date.year}-${date.month}-${date.day}";
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3F2FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active, color: Color(0xFF1B3B5A), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                              const SizedBox(height: 6),
                              Text(body, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
                              const SizedBox(height: 8),
                              Text(timeString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('لا توجد إشعارات جديدة', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}