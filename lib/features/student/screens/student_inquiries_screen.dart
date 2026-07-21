import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/student_service.dart';

class StudentInquiriesScreen extends StatefulWidget {
  final String teacherId;
  const StudentInquiriesScreen({super.key, required this.teacherId});

  @override
  State<StudentInquiriesScreen> createState() => _StudentInquiriesScreenState();
}

class _StudentInquiriesScreenState extends State<StudentInquiriesScreen> {
  final StudentService _studentService = StudentService();
  final TextEditingController _questionController = TextEditingController();
  
  String studentName = 'طالب';
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
  }

  Future<void> _fetchStudentName() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted) {
        setState(() {
          studentName = doc.data()?['name'] ?? 'طالب';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B3B5A))),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B3B5A),
            title: const Text('استفساراتي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'تم الرد'),
                Tab(text: 'قيد الانتظار'),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _studentService.getStudentInquiries(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('اسأل مدرسك وسيجيب عليك هنا!', style: TextStyle(color: Colors.grey, fontSize: 16)));
                    }

                    var inquiries = snapshot.data!.docs;
                    
                    var teacherInquiries = inquiries.where((doc) => doc['teacherId'] == widget.teacherId).toList();

                    if (teacherInquiries.isEmpty) {
                      return const Center(child: Text('لم ترسل أي استفسار لهذا المدرس بعد', style: TextStyle(color: Colors.grey, fontSize: 16)));
                    }

                    var answeredInquiries = teacherInquiries.where((doc) => (doc['answer'] ?? '').toString().isNotEmpty).toList();
                    var pendingInquiries = teacherInquiries.where((doc) => (doc['answer'] ?? '').toString().isEmpty).toList();

                    answeredInquiries.sort((a, b) => (b['timestamp'] as Timestamp? ?? Timestamp.now()).compareTo(a['timestamp'] as Timestamp? ?? Timestamp.now()));
                    pendingInquiries.sort((a, b) => (b['timestamp'] as Timestamp? ?? Timestamp.now()).compareTo(a['timestamp'] as Timestamp? ?? Timestamp.now()));

                    return TabBarView(
                      children: [
                        _buildInquiriesList(answeredInquiries, isAnswered: true),
                        _buildInquiriesList(pendingInquiries, isAnswered: false),
                      ],
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: 'اكتب استفساراً جديداً...',
                          filled: true,
                          fillColor: const Color(0xFFF0F2F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isSending ? null : () async {
                        if (_questionController.text.trim().isEmpty) return;

                        setState(() => _isSending = true);
                        
                        String result = await _studentService.sendInquiry(
                          teacherId: widget.teacherId,
                          studentName: studentName,
                          question: _questionController.text.trim(),
                        );

                        setState(() => _isSending = false);

                        if (result == "success") {
                          _questionController.clear();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال السؤال!'), backgroundColor: Colors.green));
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFF2B4D7E), shape: BoxShape.circle),
                        child: _isSending 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInquiriesList(List<DocumentSnapshot> list, {required bool isAnswered}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isAnswered ? 'لا توجد أسئلة مجاب عنها حتى الآن' : 'لا توجد أسئلة قيد الانتظار', 
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
        String question = inquiry['question'] ?? '';
        String answer = inquiry['answer'] ?? '';

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          onDismissed: (direction) {
            _studentService.deleteInquiry(id);
          },
          child: Card(
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
                          Icon(isAnswered ? Icons.check_circle : Icons.access_time_filled, color: isAnswered ? Colors.green : Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(isAnswered ? 'تم الرد' : 'قيد الانتظار', style: TextStyle(color: isAnswered ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _studentService.deleteInquiry(id),
                      )
                    ],
                  ),
                  const Divider(),
                  const Text('سؤالك:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3B5A))),
                  
                  if (isAnswered) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إجابة المدرس:', style: TextStyle(color: Color(0xFF1B3B5A), fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(answer, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}