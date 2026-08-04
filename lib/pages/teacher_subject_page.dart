import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import 'attendance_summary_page.dart';

class TeacherSubjectPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  const TeacherSubjectPage({super.key, required this.subjectId, required this.subjectName});

  @override
  State<TeacherSubjectPage> createState() => _TeacherSubjectPageState();
}

class _TeacherSubjectPageState extends State<TeacherSubjectPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  int _secondsLeft(Timestamp? expiresAt) {
    if (expiresAt == null) return 0;
    final diff = expiresAt.toDate().difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.subjectStream(widget.subjectId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final activeCode = data?['activeCode'];
          final codeExpiresAt = data?['codeExpiresAt'] as Timestamp?;
          final enrollCode = data?['enrollCode'] as String? ?? '';
          final secondsLeft = _secondsLeft(codeExpiresAt);
          final isLive = activeCode != null && secondsLeft > 0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Enrollment code for students',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text(enrollCode,
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
                      const SizedBox(height: 4),
                      const Text('Share this once — students use it to enroll.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<int>(
                stream: _firestoreService.totalClassesStream(widget.subjectId),
                builder: (context, totalSnap) {
                  final totalClasses = totalSnap.data ?? 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total classes held',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text('$totalClasses',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.bar_chart),
                            label: const Text('Summary'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AttendanceSummaryPage(
                                    subjectId: widget.subjectId,
                                    subjectName: widget.subjectName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (isLive) ...[
                        const Text('Show this code to your class:', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 12),
                        Text(
                          activeCode,
                          style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        Text('Expires in ${secondsLeft}s',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ] else ...[
                        const Icon(Icons.qr_code, size: 50, color: AppColors.primary),
                        const SizedBox(height: 12),
                        const Text('No code is currently active', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Generate Code (valid 10s)', style: TextStyle(fontSize: 15)),
                            onPressed: () => _firestoreService.startSession(widget.subjectId),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Present today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.presentTodayStream(widget.subjectId),
                builder: (context, presentSnap) {
                  final present = presentSnap.data ?? [];
                  if (present.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No one has checked in yet today.', style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return Column(
                    children: present
                        .map(
                          (s) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.check_circle, color: AppColors.primary),
                              title: Text(s['name'] ?? ''),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
