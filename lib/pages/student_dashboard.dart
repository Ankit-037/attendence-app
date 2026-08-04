import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'role_selection_page.dart';
import 'student_subject_page.dart';

class StudentDashboard extends StatelessWidget {
  final AppUser user;
  StudentDashboard({super.key, required this.user});

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  void _showEnrollDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String? errorText;
          return AlertDialog(
            title: const Text('Enroll in a Course'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter course code',
                border: const OutlineInputBorder(),
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final result = await _firestoreService.enrollInSubject(
                    code: controller.text,
                    studentId: user.uid,
                    studentName: user.name,
                  );
                  if (result['success'] == true) {
                    if (context.mounted) Navigator.pop(context);
                  } else {
                    setState(() {
                      errorText = result['message'] as String? ??
                          'Something went wrong.';
                    });
                  }
                },
                child: const Text('Enroll'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLeave(
      BuildContext context, String subjectId, String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Course'),
        content: Text(
          'Remove "$subjectName" from your dashboard? Your attendance history stays with your teacher.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _firestoreService.leaveSubject(subjectId, user.uid);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RoleSelectionPage()),
                    (route) => false);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Enroll in Course'),
        onPressed: () => _showEnrollDialog(context),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${user.name}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    'Tap a course to check in when your teacher starts a session'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestoreService.myEnrolledSubjects(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'You are not enrolled in any course yet.\nTap "Enroll in Course" and enter the code your teacher gave you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final subjectId = data['subjectId'] as String? ?? doc.id;
                    final name = data['name'] ?? '';
                    final teacherName = data['teacherName'] ?? '';

                    return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _firestoreService.subjectStream(subjectId),
                      builder: (context, subjectSnap) {
                        final subjectData = subjectSnap.data?.data();
                        final activeCode = subjectData?['activeCode'];
                        final codeExpiresAt =
                            subjectData?['codeExpiresAt'] as Timestamp?;
                        final isLive = activeCode != null &&
                            codeExpiresAt != null &&
                            DateTime.now().isBefore(codeExpiresAt.toDate());

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isLive ? Colors.orange : Colors.blue,
                              child:
                                  const Icon(Icons.book, color: Colors.white),
                            ),
                            title: Text(name),
                            subtitle: Text(isLive
                                ? 'Attendance code is live now!'
                                : 'Taught by $teacherName'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLive)
                                  const Icon(Icons.fiber_manual_record,
                                      color: Colors.red, size: 14),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'leave')
                                      _confirmLeave(context, subjectId, name);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                        value: 'leave',
                                        child: Text('Leave Course')),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentSubjectPage(
                                    subjectId: subjectId,
                                    subjectName: name,
                                    student: user,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
