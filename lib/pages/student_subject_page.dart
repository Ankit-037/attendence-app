import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';
import 'attendance_history_page.dart';

class StudentSubjectPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final AppUser student;

  const StudentSubjectPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.student,
  });

  @override
  State<StudentSubjectPage> createState() => _StudentSubjectPageState();
}

class _StudentSubjectPageState extends State<StudentSubjectPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _codeController = TextEditingController();
  Timer? _tickTimer;
  String? _feedback;
  Color _feedbackColor = Colors.green;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tickTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  int _secondsLeft(Timestamp? expiresAt) {
    if (expiresAt == null) return 0;
    final diff = expiresAt.toDate().difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff + 1;
  }

  Future<void> _submitCode() async {
    setState(() => _submitting = true);
    final success = await _firestoreService.markAttendance(
      subjectId: widget.subjectId,
      studentId: widget.student.uid,
      studentName: widget.student.name,
      enteredCode: _codeController.text,
    );
    setState(() {
      _submitting = false;
      if (success) {
        _feedback =
            'Attendance marked! You are present for ${widget.subjectName} today.';
        _feedbackColor = Colors.green;
      } else {
        _feedback =
            'Incorrect or expired code. Try again next time your teacher starts a session.';
        _feedbackColor = Colors.red;
      }
    });
    _codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.subjectName), backgroundColor: Colors.blue),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.subjectStream(widget.subjectId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final activeCode = data?['activeCode'];
          final codeExpiresAt = data?['codeExpiresAt'] as Timestamp?;
          final secondsLeft = _secondsLeft(codeExpiresAt);
          final isLive = activeCode != null && secondsLeft > 0;

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              StreamBuilder<int>(
                stream: _firestoreService.totalClassesStream(widget.subjectId),
                builder: (context, totalSnap) {
                  final totalClasses = totalSnap.data ?? 0;
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestoreService
                        .attendanceCollectionStream(widget.subjectId),
                    builder: (context, attSnap) {
                      int myCount = 0;
                      if (attSnap.hasData) {
                        for (final doc in attSnap.data!.docs) {
                          final present =
                              (doc.data()['present'] as List?) ?? [];
                          if (present
                              .any((e) => e['id'] == widget.student.uid)) {
                            myCount++;
                          }
                        }
                      }
                      return Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 10),
                              Text(
                                'You attended $myCount of $totalClasses classes',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('View Full Attendance History'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceHistoryPage(
                          subjectId: widget.subjectId,
                          subjectName: widget.subjectName,
                          studentId: widget.student.uid,
                          studentName: widget.student.name,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              if (isLive) ...[
                const Icon(Icons.timer, size: 60, color: Colors.orange),
                const SizedBox(height: 12),
                Text('${secondsLeft}s left to enter the code',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 8),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                    hintText: '0000',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white),
                    onPressed: _submitting ? null : _submitCode,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Submit Code',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ] else ...[
                const Icon(Icons.hourglass_empty, size: 70, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No attendance session is active right now.\nWait for your teacher to start one — you will\nonly have 10 seconds to enter the code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              if (_feedback != null) ...[
                const SizedBox(height: 24),
                Text(_feedback!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _feedbackColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ],
            ],
          );
        },
      ),
    );
  }
}
