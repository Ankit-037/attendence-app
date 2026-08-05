# Attendance App

A mobile attendance system built with Flutter and Firebase. Teachers create courses, share a one-time enrollment code with their students, and take attendance each class using a short-lived, auto-expiring code — no more marking attendance for a friend who isn't in the room.

## Features

- **Separate teacher and student roles**, each with their own dashboard and sign-up/login flow
- **Course enrollment system** — a teacher creates a course and gets a unique enrollment code; students enter that code once to join the course
- **Proxy-resistant attendance codes** — the teacher generates a random 4-digit code each session that is only valid for 10 seconds, so a student has to be present in class to catch and submit it in time
- **Real-time sync across devices** — the code appearing on the teacher's screen and a student marking themselves present both update instantly on everyone else's screen, powered by Firebase Firestore
- **Attendance summary** — every course has a summary screen showing total classes held and each student's attendance count and percentage
- **Date-by-date attendance history** — tapping a student in the summary (or a student viewing their own record) shows a full list of every class date marked Present or Absent
- **Students can track their own attendance** — a live counter on each course page shows "You attended X of Y classes"
- **Course management** — teachers can delete a course (and all of its data) at any time; students can leave a course while their attendance history is preserved for the teacher's records
- **Persistent login** — once signed in, a user stays logged in across app restarts until they explicitly sign out

## Tech Stack

- **Flutter** (Dart) for the mobile app
- **Firebase Authentication** (Email/Password) for login and sign-up
- **Cloud Firestore** for real-time data storage and syncing

## Download and Install

1. Go to the Releases page of this repository (or the link shared with you) and download the latest `.apk` file.
2. On your Android phone, open the downloaded file. If prompted, allow installation from this source under **Settings → Security** (the exact wording varies by phone).
3. Tap **Install** and open the app once it finishes.
4. Choose **Login** or **Sign Up**, then pick **Student** or **Teacher**.

No Apple/iOS build is provided at this time — the app currently targets Android.


## How to Use

### As a teacher

1. Open the app and choose **Teacher Login**, then sign up for an account.
2. From the dashboard, tap **Add Course** and give it a name.
3. Open the course to see its unique **enrollment code** — share this with your students once so they can join.
4. When class starts, tap **Generate Code**. A 4-digit code appears and stays valid for 10 seconds — read it out or display it to the class.
5. Students who enter the code in time appear under **Present today**.
6. Tap **Summary** at any time to see total classes held and each student's attendance record. Tap a student's name to see their full date-by-date history.
7. Delete a course from the dashboard menu if it's no longer needed.

### As a student

1. Open the app and choose **Student Login**, then sign up for an account.
2. Tap **Enroll in Course** and enter the code your teacher shared with you.
3. When your teacher starts a session, the course will show a live indicator. Open it, type the code you're shown within 10 seconds, and submit.
4. Each course page shows how many classes you've attended out of the total held so far. Tap **View Full Attendance History** for the complete Present/Absent list by date.
5. Leave a course from the dashboard menu if you no longer need it — your attendance record stays with your teacher.
