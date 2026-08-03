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
                    'Tap a subject to check in when your teacher starts a session'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestoreService.allSubjects(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No subjects available yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final name = data['name'] ?? '';
                    final teacherName = data['teacherName'] ?? '';
                    final activeCode = data['activeCode'];
                    final codeExpiresAt = data['codeExpiresAt'] as Timestamp?;
                    final isLive = activeCode != null &&
                        codeExpiresAt != null &&
                        DateTime.now().isBefore(codeExpiresAt.toDate());

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLive ? Colors.orange : Colors.blue,
                          child: const Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          isLive
                              ? 'Attendance code is live now!'
                              : 'Taught by $teacherName',
                        ),
                        trailing: isLive
                            ? const Icon(Icons.fiber_manual_record,
                                color: Colors.red, size: 14)
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentSubjectPage(
                                subjectId: doc.id,
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
            ),
          ),
        ],
      ),
    );
  }
}
