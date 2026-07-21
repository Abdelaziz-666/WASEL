import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_service.dart';

class StudentNotificationsScreen extends StatefulWidget {
  final String teacherId;
  final String stage;
  final String groupName;

  const StudentNotificationsScreen({
    super.key, 
    required this.teacherId, 
    required this.stage, 
    required this.groupName,
  });

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  final StudentService _studentService = StudentService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('الإشعارات والتنبيهات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _studentService.getStudentNotifications(widget.teacherId),
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
                var data = doc.data() as Map<String, dynamic>;
                String targetType = data['targetType'] ?? 'all';

                if (targetType == 'all') return true;
                
                if (targetType == 'stage') {
                  String? notifStage = data['stage'];
                  return notifStage == widget.stage;
                }

                if (targetType == 'group') {
                  String? notifStage = data['stage'];
                  String? notifGroup = data['group'];
                  return notifStage == widget.stage && notifGroup == widget.groupName;
                }

                return false;
              } catch (e) {
                return false;
              }
            }).toList();

            filteredNotifications.sort((a, b) {
              try {
                Timestamp timeA = a.get('timestamp') ?? Timestamp.now();
                Timestamp timeB = b.get('timestamp') ?? Timestamp.now();
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
                  timeString = "${date.year}-${date.month}-${date.day} | ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
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