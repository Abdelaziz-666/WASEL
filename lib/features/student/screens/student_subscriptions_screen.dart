import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/student_service.dart';

class StudentSubscriptionsScreen extends StatefulWidget {
  final String teacherId;
  final String stage;
  final String groupName;

  const StudentSubscriptionsScreen({
    super.key,
    required this.teacherId,
    required this.stage,
    required this.groupName,
  });

  @override
  State<StudentSubscriptionsScreen> createState() => _StudentSubscriptionsScreenState();
}

class _StudentSubscriptionsScreenState extends State<StudentSubscriptionsScreen> {
  final StudentService _studentService = StudentService();
  int _selectedYear = DateTime.now().year;

  final List<int> _years = [2024, 2025, 2026, 2027, 2028];
  final List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  Widget build(BuildContext context) {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B3B5A),
          title: const Text('سجل الاشتراكات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: InputDecoration(
                  hintText: 'اختر السنة',
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF1B3B5A)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _years.map((y) => DropdownMenuItem(value: y, child: Text('سنة $y'))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedYear = val!;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _studentService.getStudentPayments(widget.teacherId, widget.stage, widget.groupName, _selectedYear),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<int, bool> monthPayments = {};
                  
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    for (var doc in snapshot.data!.docs) {
                      int month = doc['month'];
                      Map<String, dynamic> records = doc['records'] ?? {};
                      
                      if (currentUserId != null && records.containsKey(currentUserId)) {
                        monthPayments[month] = records[currentUserId] == true;
                      }
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      int currentMonthNumber = index + 1;
                      bool isPaid = monthPayments[currentMonthNumber] == true;
                      bool isNotRecordedYet = !monthPayments.containsKey(currentMonthNumber);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isNotRecordedYet 
                                  ? Colors.grey.shade100 
                                  : (isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.payments_outlined,
                              color: isNotRecordedYet 
                                  ? Colors.grey 
                                  : (isPaid ? Colors.green : Colors.red),
                            ),
                          ),
                          title: Text(
                            'شهر ${_arabicMonths[index]}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B5A)),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isNotRecordedYet 
                                  ? Colors.grey.shade200 
                                  : (isPaid ? Colors.green : Colors.red),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isNotRecordedYet ? 'لم يُسجل بعد' : (isPaid ? 'مدفوع' : 'غير مدفوع'),
                              style: TextStyle(
                                color: isNotRecordedYet ? Colors.black54 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}