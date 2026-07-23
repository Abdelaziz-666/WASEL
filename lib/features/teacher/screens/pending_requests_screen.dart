import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/teacher_service.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final TeacherService _teacherService = TeacherService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text(
            'طلبات الانضمام',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _teacherService.getPendingRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1B3B5A)));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_off_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد طلبات انضمام جديدة',
                      style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            var requests = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                var request = requests[index];
                String requestId = request.id;
                String studentName = request['studentName'] ?? 'طالب';
                String studentPhone = request['studentPhone'] ?? 'غير متوفر';
                String stage = request['stage'] ?? '';
                String group = request['group'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE3F2FD),
                              radius: 24,
                              child: Icon(Icons.person, color: Color(0xFF1B3B5A)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B3B5A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    studentPhone,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.school, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(stage, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.group, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(group, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        
                                        setState(() => _isProcessing = true);
                                        String result = await _teacherService.approveRequest(requestId);
                                        
                                        if (!mounted) return;
                                        setState(() => _isProcessing = false);

                                        if (result == "success") {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text('تم قبول الطالب بنجاح'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(result),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'موافقة',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        
                                        setState(() => _isProcessing = true);
                                        String studentId = request['studentId'];
                                        String result = await _teacherService.rejectStudent(studentId);
                                        
                                        if (!mounted) return;
                                        setState(() => _isProcessing = false);

                                        if (result == "success") {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text('تم رفض الطلب'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(result),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'رفض',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
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
}