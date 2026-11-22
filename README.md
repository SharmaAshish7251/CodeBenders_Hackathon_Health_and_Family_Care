# Problem Statement 4 | Health and Family Care
# The Family Care Hub
/ideas/Problem Statement 4 Health and Family Care.pdf

# Family Care Hub (Health and Family Care)

A Flutter app that lets a family share the care of an elderly relative: care tasks, medicines, appointments, health records, and a shared timeline, all kept on the device. The app is available in English and Hindi.

# Demo Video and released apk 
https://drive.google.com/drive/folders/140OQwUq6VMQzHEGIgFFJobvY5JyE7vo9?usp=sharing

## Features

- **Onboarding**: three intro cards explaining the shared family hub, WhatsApp care summaries, and offline-first privacy.
- **Sign in**: enter your name and phone number to create a local profile on the device.
- **Family setup and members**: set up your family group, add members, and see each member's role and relation.
- **Role switching**: switch the active person from a bottom sheet. Your role controls what you can edit.
- **Care tasks**: create tasks, mark them complete, update them, reassign them to another member, or delete them.
- **Reminders**: schedule a reminder for a task; it shows as a local notification at the chosen time.
- **Medicines**: keep a medicine list. Requesting a refill creates a "Refill Task".
- **Appointments**: book a doctor appointment, which is then shown as scheduled.
- **Health records**: add, edit, and delete records such as vitals. Some records can be marked caregivers-only and are hidden from read-only viewers.
- **Scan prescriptions and reports (OCR)**: pick a photo from the camera or gallery, extract its text on the device, review and correct it, then save.
- **Timeline**: a chronological view of care activity.
- **Settings**: privacy and data-handling information.

## Roles

Each member has a role that decides what they can do:

- **Admin**: manages the family and everything in it.
- **Caregiver**: manages day-to-day tasks, medicines, and records.
- **Clinical support**: works with health records and appointments.
- **Viewer**: read-only access; caregivers-only records are hidden.
- **Elder**: the care recipient.

## Getting started

### Requirements

- Flutter SDK with Dart 3.12 or newer (see `environment.sdk` in `pubspec.yaml`).
- An Android device or emulator, or an iOS device or simulator.

### Run the app

1. Clone the repository and open the project folder.
2. Get the dependencies:
   ```
   flutter pub get
   ```
3. Run the app:
   ```
   flutter run
   ```

The Android and iOS platform folders are not included in this repository. Create them with `flutter create .` before running, then allow camera, photo library, and notification permissions when the app asks.

## First-time user guide

1. **Open the app.** On a new install, the app shows a few introduction screens. Read them and continue to sign in.
2. **Choose how to start.** The sign-in screen has two tabs:
   - **Explore Demo** (selected by default): loads sample family data so you can look around right away. Use this to try the app before entering real information.
   - **Setup Manually**: enter your own details to start a new profile.
3. **Continue to family setup.** Tap **Continue to Family Setup**. Then either create a new family by giving it a name, or join an existing family with an invite code.
4. **Add your first task.** Open the tasks screen and create a task. The form has a title, a description, a due date, an assignee, and a recurrence setting. Save it to add the task to the list.
5. **Explore the rest of the app.** The sections below describe each feature and how to use it.

## How to use the app

1. **First launch**: read the three intro cards and tap through to sign in.
2. **Sign in**: enter your name and phone number.
3. **Set up the family**: add the members who will share the care and assign each one a role.
4. **Add tasks**: create a task with a title, description, due date, and assignee.
5. **Track medicines and appointments**: add medicines, request refills, and book appointments.
6. **Save health records**: add vitals and notes manually, or scan a prescription or report with the camera or gallery and check the text before saving.
7. **Follow activity**: open the timeline to see what has been done and by whom.
8. **Switch roles**: use the role switcher to act as another family member and see what their role allows.

## Privacy

Data is stored locally on the device in a local database and preferences. OCR runs on the device. The app does not currently sign in to a cloud account.

## Language

English and Hindi are supported.
