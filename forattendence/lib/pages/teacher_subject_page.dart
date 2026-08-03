import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class TeacherSubjectPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  const TeacherSubjectPage(
      {super.key, required this.subjectId, required this.subjectName});

  @override
  State<TeacherSubjectPage> createState() => _TeacherSubjectPageState();
}

class _TeacherSubjectPageState extends State<TeacherSubjectPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
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
      appBar: AppBar(
          title: Text(widget.subjectName), backgroundColor: Colors.green),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.subjectStream(widget.subjectId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final activeCode = data?['activeCode'];
          final codeExpiresAt = data?['codeExpiresAt'] as Timestamp?;
          final secondsLeft = _secondsLeft(codeExpiresAt);
          final isLive = activeCode != null && secondsLeft > 0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: isLive ? Colors.orange.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (isLive) ...[
                        const Text('Show this code to your class:',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 12),
                        Text(
                          activeCode,
                          style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8),
                        ),
                        const SizedBox(height: 8),
                        Text('Expires in ${secondsLeft}s',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold)),
                      ] else ...[
                        const Icon(Icons.qr_code,
                            size: 50, color: Colors.green),
                        const SizedBox(height: 12),
                        const Text('No code is currently active',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Generate Code (valid 5s)',
                                style: TextStyle(fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            onPressed: () => _firestoreService
                                .startSession(widget.subjectId),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Present today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.presentTodayStream(widget.subjectId),
                builder: (context, presentSnap) {
                  final present = presentSnap.data ?? [];
                  if (present.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No one has checked in yet today.',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return Column(
                    children: present
                        .map(
                          (s) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.check_circle,
                                  color: Colors.green),
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
