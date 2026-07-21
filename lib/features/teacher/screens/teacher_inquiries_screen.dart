import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/teacher_service.dart';

class TeacherInquiriesScreen extends StatefulWidget {
  const TeacherInquiriesScreen({super.key});

  @override
  State<TeacherInquiriesScreen> createState() => _TeacherInquiriesScreenState();
}

class _TeacherInquiriesScreenState extends State<TeacherInquiriesScreen> {
  final TeacherService _teacherService = TeacherService();
  bool _isSending = false;

  void _showReplyDialog(String inquiryId, String studentName, String question) {
    TextEditingController answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('الرد على $studentName', style: const TextStyle(color: Color(0xFF1B3B5A), fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(8)),
                  child: Text('السؤال: $question', style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: answerController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'اكتب إجابتك هنا...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _isSending ? null : () async {
                  if (answerController.text.trim().isEmpty) return;
                  
                  setState(() => _isSending = true);
                  String result = await _teacherService.answerInquiry(inquiryId, answerController.text.trim());
                  setState(() => _isSending = false);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  
                  if (result == "success") {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الرد بنجاح'), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B4D7E)),
                child: const Text('إرسال الرد', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B3B5A),
            title: const Text('استفسارات الطلاب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'بانتظار الرد'),
                Tab(text: 'تم الرد عليها'),
              ],
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _teacherService.getTeacherInquiries(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد استفسارات حتى الآن', style: TextStyle(color: Colors.grey, fontSize: 16)));
              }

              var inquiries = snapshot.data!.docs;
              
              var pendingInquiries = inquiries.where((doc) => (doc['answer'] ?? '').toString().isEmpty).toList();
              var answeredInquiries = inquiries.where((doc) => (doc['answer'] ?? '').toString().isNotEmpty).toList();

              pendingInquiries.sort((a, b) => (b['timestamp'] as Timestamp? ?? Timestamp.now()).compareTo(a['timestamp'] as Timestamp? ?? Timestamp.now()));
              answeredInquiries.sort((a, b) => (b['timestamp'] as Timestamp? ?? Timestamp.now()).compareTo(a['timestamp'] as Timestamp? ?? Timestamp.now()));

              return TabBarView(
                children: [
                  _buildInquiriesList(pendingInquiries, isAnswered: false),
                  _buildInquiriesList(answeredInquiries, isAnswered: true),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInquiriesList(List<DocumentSnapshot> list, {required bool isAnswered}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isAnswered ? 'لم تقم بالرد على أي سؤال بعد' : 'لا توجد أسئلة جديدة بانتظار الرد', 
          style: const TextStyle(color: Colors.grey, fontSize: 16)
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        var inquiry = list[index];
        String id = inquiry.id;
        String studentName = inquiry['studentName'] ?? 'طالب';
        String question = inquiry['question'] ?? '';
        String answer = inquiry['answer'] ?? '';
        
        Timestamp? timestamp = inquiry['timestamp'];
        String timeString = '';
        if (timestamp != null) {
          DateTime date = timestamp.toDate();
          timeString = "${date.year}-${date.month}-${date.day}";
        }

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE3F2FD),
                          radius: 16,
                          child: Icon(Icons.person, color: Color(0xFF1B3B5A), size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B5A))),
                      ],
                    ),
                    Text(timeString, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                const Text('السؤال:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(question, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                
                if (isAnswered) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ردك:', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(answer, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReplyDialog(id, studentName, question),
                      icon: const Icon(Icons.reply, color: Colors.white, size: 20),
                      label: const Text('رد على السؤال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B4D7E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}