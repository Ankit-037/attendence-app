import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'attendance_history_page.dart';

class AttendanceSummaryPage extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  AttendanceSummaryPage(
      {super.key, required this.subjectId, required this.subjectName});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$subjectName - Summary')),
      body: StreamBuilder<int>(
        stream: _firestoreService.totalClassesStream(subjectId),
        builder: (context, totalSnap) {
          final totalClasses = totalSnap.data ?? 0;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestoreService.attendanceCollectionStream(subjectId),
            builder: (context, attSnap) {
              if (!attSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final Map<String, Map<String, dynamic>> studentCounts = {};
              for (final doc in attSnap.data!.docs) {
                final present = (doc.data()['present'] as List?) ?? [];
                for (final entry in present) {
                  final id = entry['id'] as String;
                  final name = entry['name'] as String;
                  studentCounts.putIfAbsent(
                      id, () => {'name': name, 'count': 0});
                  studentCounts[id]!['count'] =
                      (studentCounts[id]!['count'] as int) + 1;
                }
              }
              final students = studentCounts.entries.toList()
                ..sort((a, b) => (b.value['count'] as int)
                    .compareTo(a.value['count'] as int));

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Total classes held so far',
                              style: TextStyle(fontSize: 15)),
                          const SizedBox(height: 6),
                          Text('$totalClasses',
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Student attendance',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap a student to see their date-by-date attendance.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (students.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No attendance recorded yet.'),
                    )
                  else
                    ...students.map((entry) {
                      final id = entry.key;
                      final name = entry.value['name'] as String;
                      final count = entry.value['count'] as int;
                      final percent = totalClasses > 0
                          ? (count / totalClasses * 100).round()
                          : 0;
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('$count / $totalClasses classes'),
                          trailing: Text(
                            '$percent%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: percent >= 75
                                  ? Colors.greenAccent
                                  : (percent >= 50
                                      ? Colors.orangeAccent
                                      : Colors.redAccent),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendanceHistoryPage(
                                  subjectId: subjectId,
                                  subjectName: subjectName,
                                  studentId: id,
                                  studentName: name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
