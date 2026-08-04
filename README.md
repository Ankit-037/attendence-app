
# Attendance App

A mobile attendance system built with Flutter and Firebase. Teachers create courses, share a one-time enrollment code with their students, and take attendance each class using a short-lived, auto-expiring code — no more marking attendance for a friend who isn't in the room.

## Features

- **Separate teacher and student roles**, each with their own dashboard and sign-up/login flow
- **Course enrollment system** — a teacher creates a course and gets a unique enrollment code; students enter that code once to join the course
- **Proxy-resistant attendance codes** — the teacher generates a random 4-digit code each session that is only valid for 10 seconds, so a student has to be present in class to catch and submit it in time
- **Real-time sync across devices** — the code appearing on the teacher's screen and a student marking themselves present both update instantly on everyone else's screen, powered by Firebase Firestore
- **Attendance history and summary** — every class session is logged with its date, and each course has a summary screen showing total classes held and each student's attendance count and percentage
- **Students can track their own attendance** — a live counter on each course page shows "You attended X of Y classes"
- **Course management** — teachers can delete a course (and all of its data) at any time; students can leave a course while their attendance history is preserved for the teacher's records
- **Persistent login** — once signed in, a user stays logged in across app restarts until they explicitly sign out

## Tech Stack

- **Flutter** (Dart) for the mobile app
- **Firebase Authentication** (Email/Password) for login and sign-up
- **Cloud Firestore** for real-time data storage and syncing

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev) installed
- A [Firebase](https://console.firebase.google.com) project with:
  - **Authentication** enabled with the **Email/Password** sign-in provider
  - **Cloud Firestore** database created

### Setup

1. Clone this repository:
   ```
   git clone https://github.com/Ankit-037/attendence-app.git
   cd attendence-app
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Connect the app to your own Firebase project. Install the FlutterFire CLI if you don't already have it:
   ```
   dart pub global activate flutterfire_cli
   ```
   Then run the following from the project root and follow the prompts to select your Firebase project and target platforms:
   ```
   flutterfire configure
   ```
   This generates a working `lib/firebase_options.dart` file for your project.

4. In the Firebase Console, open **Firestore Database → Rules** and publish the rules found in `firestore.rules` in this repository.

5. Run the app:
   ```
   flutter run
   ```

## How to Use

### As a teacher

1. Open the app and choose **Teacher Login**, then sign up for an account.
2. From the dashboard, tap **Add Course** and give it a name.
3. Open the course to see its unique **enrollment code** — share this with your students once so they can join.
4. When class starts, tap **Generate Code**. A 4-digit code appears and stays valid for 10 seconds — read it out or display it to the class.
5. Students who enter the code in time appear under **Present today**.
6. Tap **Summary** at any time to see total classes held and each student's attendance record.
7. Delete a course from the dashboard menu if it's no longer needed.

### As a student

1. Open the app and choose **Student Login**, then sign up for an account.
2. Tap **Enroll in Course** and enter the code your teacher shared with you.
3. When your teacher starts a session, the course will show a live indicator. Open it, type the code you're shown within 10 seconds, and submit.
4. Each course page shows how many classes you've attended out of the total held so far.
5. Leave a course from the dashboard menu if you no longer need it — your attendance record stays with your teacher.
