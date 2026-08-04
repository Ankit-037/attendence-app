import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final String studentId;
  final String studentName;

  AttendanceHistoryPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.studentId,
    required this.studentName,
  });

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$studentName - $subjectName')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.classDaysStream(subjectId),
        builder: (context, classDaysSnap) {
          if (!classDaysSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestoreService.attendanceCollectionStream(subjectId),
            builder: (context, attSnap) {
              if (!attSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final Map<String, bool> presentByDate = {};
              for (final doc in attSnap.data!.docs) {
                final present = (doc.data()['present'] as List?) ?? [];
                presentByDate[doc.id] =
                    present.any((e) => e['id'] == studentId);
              }

              final dates = classDaysSnap.data!.docs.map((d) => d.id).toList();
              final presentCount =
                  dates.where((d) => presentByDate[d] == true).length;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Present $presentCount of ${dates.length} classes',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: dates.isEmpty
                        ? const Center(
                            child: Text('No classes recorded yet.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: dates.length,
                            itemBuilder: (context, index) {
                              final date = dates[index];
                              final present = presentByDate[date] == true;
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    present ? Icons.check_circle : Icons.cancel,
                                    color: present
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                  ),
                                  title: Text(date),
                                  trailing: Text(
                                    present ? 'Present' : 'Absent',
                                    style: TextStyle(
                                      color: present
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
