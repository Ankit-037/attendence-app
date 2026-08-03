import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles all Firestore reads/writes for subjects, live attendance codes,
/// and daily attendance records.
///
/// Firestore layout:
///   subjects/{subjectId}
///       name: String
///       teacherId: String
///       teacherName: String
///       activeCode: String?          <- current live code (or null)
///       codeExpiresAt: Timestamp?    <- when that code stops being valid
///     subjects/{subjectId}/attendance/{yyyy-mm-dd}
///         present: List<Map>  [{id, name}, ...]
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const sessionSeconds = 5;

  CollectionReference<Map<String, dynamic>> get _subjects =>
      _db.collection('subjects');

  // ---------------------------------------------------------------------
  // Subjects
  // ---------------------------------------------------------------------

  /// All subjects created by a specific teacher (for the teacher dashboard).
  Stream<QuerySnapshot<Map<String, dynamic>>> teacherSubjects(
      String teacherId) {
    return _subjects.where('teacherId', isEqualTo: teacherId).snapshots();
  }

  /// All subjects in the system (for the student dashboard, so students can
  /// see every class being offered). In a bigger app you'd scope this to
  /// subjects the student is enrolled in.
  Stream<QuerySnapshot<Map<String, dynamic>>> allSubjects() {
    return _subjects.snapshots();
  }

  Future<void> addSubject({
    required String name,
    required String teacherId,
    required String teacherName,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _subjects.add({
      'name': trimmed,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'activeCode': null,
      'codeExpiresAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Live stream of one subject document (used to watch for a code turning
  /// on/off in real time on both the teacher's and students' screens).
  Stream<DocumentSnapshot<Map<String, dynamic>>> subjectStream(
      String subjectId) {
    return _subjects.doc(subjectId).snapshots();
  }

  // ---------------------------------------------------------------------
  // Attendance code session
  // ---------------------------------------------------------------------

  /// Teacher taps "Generate Code": writes a random 4-digit code plus an
  /// expiry timestamp exactly [sessionSeconds] seconds from now. Every
  /// device (teacher's and students') simply compares this timestamp to
  /// the current time — nobody needs to remember to "turn the code off".
  Future<void> startSession(String subjectId) async {
    final code = (1000 + Random().nextInt(9000)).toString();
    final expiresAt = Timestamp.fromDate(
      DateTime.now().add(const Duration(seconds: sessionSeconds)),
    );
    await _subjects.doc(subjectId).update({
      'activeCode': code,
      'codeExpiresAt': expiresAt,
    });
  }

  /// Student submits a code. Runs as a transaction so two students can't
  /// race each other, and re-checks the expiry server-side data (not just
  /// what the client already had cached) before accepting it.
  ///
  /// NOTE: For a production app, do this validation inside a Cloud
  /// Function instead of client-side, so a student can't fake the check by
  /// modifying the app. This client-side version is fine for learning /
  /// small deployments.
  Future<bool> markAttendance({
    required String subjectId,
    required String studentId,
    required String studentName,
    required String enteredCode,
  }) async {
    final subjectRef = _subjects.doc(subjectId);
    final subjectSnap = await subjectRef.get();
    final data = subjectSnap.data();
    if (data == null) return false;

    final activeCode = data['activeCode'] as String?;
    final codeExpiresAt = data['codeExpiresAt'] as Timestamp?;

    final isValid = activeCode != null &&
        activeCode == enteredCode.trim() &&
        codeExpiresAt != null &&
        DateTime.now().isBefore(codeExpiresAt.toDate());

    if (!isValid) return false;

    final today = _todayKey();
    final attendanceRef = subjectRef.collection('attendance').doc(today);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(attendanceRef);
      final List present = (snap.data()?['present'] as List?) ?? [];
      final alreadyIn = present.any((e) => e['id'] == studentId);
      if (!alreadyIn) {
        tx.set(
          attendanceRef,
          {
            'present': FieldValue.arrayUnion([
              {'id': studentId, 'name': studentName}
            ]),
          },
          SetOptions(merge: true),
        );
      }
    });

    return true;
  }

  /// Live stream of today's present list for a subject, shown on the
  /// teacher's subject page.
  Stream<List<Map<String, dynamic>>> presentTodayStream(String subjectId) {
    final today = _todayKey();
    return _subjects
        .doc(subjectId)
        .collection('attendance')
        .doc(today)
        .snapshots()
        .map((snap) {
      final List present = (snap.data()?['present'] as List?) ?? [];
      return present.cast<Map<String, dynamic>>();
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
