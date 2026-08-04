import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const sessionSeconds = 10;

  CollectionReference<Map<String, dynamic>> get _subjects =>
      _db.collection('subjects');

  Stream<QuerySnapshot<Map<String, dynamic>>> teacherSubjects(
      String teacherId) {
    return _subjects.where('teacherId', isEqualTo: teacherId).snapshots();
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
      'enrollCode': _generateEnrollCode(),
      'activeCode': null,
      'codeExpiresAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> subjectStream(
      String subjectId) {
    return _subjects.doc(subjectId).snapshots();
  }

  Future<void> deleteSubject(String subjectId) async {
    final subjectRef = _subjects.doc(subjectId);

    final enrolledSnap = await subjectRef.collection('enrolledStudents').get();
    final attendanceSnap = await subjectRef.collection('attendance').get();
    final classDaysSnap = await subjectRef.collection('classDays').get();

    final batch = _db.batch();

    for (final doc in enrolledSnap.docs) {
      batch.delete(doc.reference);
      final studentId = doc.id;
      batch.delete(_db
          .collection('users')
          .doc(studentId)
          .collection('enrolledSubjects')
          .doc(subjectId));
    }
    for (final doc in attendanceSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in classDaysSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(subjectRef);

    await batch.commit();
  }

  String _generateEnrollCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<Map<String, dynamic>> enrollInSubject({
    required String code,
    required String studentId,
    required String studentName,
  }) async {
    final trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) {
      return {'success': false, 'message': 'Please enter a code.'};
    }

    final query = await _subjects
        .where('enrollCode', isEqualTo: trimmedCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return {'success': false, 'message': 'No course found with this code.'};
    }

    final subjectDoc = query.docs.first;
    final subjectId = subjectDoc.id;
    final subjectData = subjectDoc.data();
    final subjectName = subjectData['name'] ?? '';
    final teacherName = subjectData['teacherName'] ?? '';

    final enrollRef =
        _subjects.doc(subjectId).collection('enrolledStudents').doc(studentId);
    final existing = await enrollRef.get();
    if (existing.exists) {
      return {
        'success': true,
        'subjectId': subjectId,
        'subjectName': subjectName
      };
    }

    final batch = _db.batch();
    batch.set(enrollRef, {
      'id': studentId,
      'name': studentName,
      'enrolledAt': FieldValue.serverTimestamp(),
    });
    final userSubjectRef = _db
        .collection('users')
        .doc(studentId)
        .collection('enrolledSubjects')
        .doc(subjectId);
    batch.set(userSubjectRef, {
      'subjectId': subjectId,
      'name': subjectName,
      'teacherName': teacherName,
      'enrolledAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return {
      'success': true,
      'subjectId': subjectId,
      'subjectName': subjectName
    };
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> myEnrolledSubjects(
      String studentId) {
    return _db
        .collection('users')
        .doc(studentId)
        .collection('enrolledSubjects')
        .snapshots();
  }

  Future<void> leaveSubject(String subjectId, String studentId) async {
    final batch = _db.batch();
    batch.delete(
        _subjects.doc(subjectId).collection('enrolledStudents').doc(studentId));
    batch.delete(_db
        .collection('users')
        .doc(studentId)
        .collection('enrolledSubjects')
        .doc(subjectId));
    await batch.commit();
  }

  Future<void> startSession(String subjectId) async {
    final code = (1000 + Random().nextInt(9000)).toString();
    final expiresAt = Timestamp.fromDate(
      DateTime.now().add(const Duration(seconds: sessionSeconds)),
    );
    await _subjects.doc(subjectId).update({
      'activeCode': code,
      'codeExpiresAt': expiresAt,
    });

    final today = _todayKey();
    await _subjects.doc(subjectId).collection('classDays').doc(today).set(
      {'date': today},
      SetOptions(merge: true),
    );
  }

  Future<bool> markAttendance({
    required String subjectId,
    required String studentId,
    required String studentName,
    required String enteredCode,
  }) async {
    final subjectRef = _subjects.doc(subjectId);

    final enrollSnap =
        await subjectRef.collection('enrolledStudents').doc(studentId).get();
    if (!enrollSnap.exists) return false;

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

  Stream<int> totalClassesStream(String subjectId) {
    return _subjects
        .doc(subjectId)
        .collection('classDays')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> attendanceCollectionStream(
      String subjectId) {
    return _subjects.doc(subjectId).collection('attendance').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> classDaysStream(
      String subjectId) {
    return _subjects
        .doc(subjectId)
        .collection('classDays')
        .orderBy('date', descending: true)
        .snapshots();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
