import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/family_member.dart';
import '../models/local_user.dart';
import '../providers/care_provider.dart';
import '../providers/emergency_provider.dart';
import '../providers/family_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/session_provider.dart';
import 'database.dart';

/// One switchable persona in demo mode.
class DemoPersona {
  final String id;
  final String name;
  final String phone;
  final Role role;
  final String relation;
  final String subtitle;
  final IconData icon;

  const DemoPersona({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.relation,
    required this.subtitle,
    required this.icon,
  });

  LocalUser toLocalUser() => LocalUser(id: id, name: name, phone: phone);
}

/// Seeds realistic demo data matching the KinPulse design mockup:
/// - Care recipient: Ramesh Sharma (Father, 72, Jaipur)
/// - Family Lead / Admin: Rahul Sharma (Bangalore)
/// - Primary Caregiver: Priya Sharma (Jaipur)
/// - Professional Nurse: Sunita Devi
/// - Low stock alert: Telmisartan (Telma 40) - 4 days left
/// - Tasks: 2 completed, 2 pending (50% progress ring)
/// - Records & Timeline items
class DemoDataSeeder {
  static const familyId = 'demo-family-ramesh';
  static const inviteCode = 'KP-7249';
  static const familyName = "Ramesh Sharma's Care Space";
  static const userRahulId = 'demo-user-rahul';
  static const userRahulName = 'Rahul (Bangalore)';
  static const userRahulPhone = '+91 98765 00001';

  /// All demo personas available for live switching in the app.
  static const personas = [
    DemoPersona(
      id: userRahulId,
      name: 'Rahul (Bangalore)',
      phone: '+91 98765 00001',
      role: Role.admin,
      relation: 'Son • Remote Organizer',
      subtitle: 'Full access • Manage roles, assign tasks & export WhatsApp updates',
      icon: Icons.admin_panel_settings_rounded,
    ),
    DemoPersona(
      id: 'demo-member-priya',
      name: 'Priya (Jaipur)',
      phone: '+91 98765 22222',
      role: Role.caregiver,
      relation: 'Daughter • Local Caregiver',
      subtitle: 'Hands-on care • Complete tasks, record vitals & refill meds',
      icon: Icons.health_and_safety_rounded,
    ),
    DemoPersona(
      id: 'demo-member-sunita',
      name: 'Sunita (Nurse)',
      phone: '+91 98765 33333',
      role: Role.caregiver,
      relation: 'Visiting Nurse',
      subtitle: 'Clinical support • Routine checks & medication compliance',
      icon: Icons.medical_services_rounded,
    ),
    DemoPersona(
      id: 'demo-member-ankit',
      name: 'Ankit (Relative)',
      phone: '+91 98765 44444',
      role: Role.viewer,
      relation: 'Extended Family • Viewer',
      subtitle: 'Read-only • Cannot edit tasks; Caregivers-only records are hidden',
      icon: Icons.visibility_rounded,
    ),
    DemoPersona(
      id: 'demo-member-ramesh',
      name: 'Ramesh Sharma',
      phone: '+91 98765 11111',
      role: Role.delegate,
      relation: 'Care Recipient (Father, 72)',
      subtitle: 'Elder profile • Recipient of coordinated family care',
      icon: Icons.elderly_rounded,
    ),
  ];

  /// Directly seeds into the database instance (e.g. at app startup).
  static Future<void> seedDirect(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_user_id', userRahulId);
    await prefs.setString('local_user_name', userRahulName);
    await prefs.setString('local_user_phone', userRahulPhone);

    await db.transaction((txn) async {
      await txn.delete(DbTables.families, where: 'id = ?', whereArgs: [familyId]);
      await txn.delete(DbTables.members, where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete(DbTables.tasks, where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete(DbTables.medicines, where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete(DbTables.records, where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete(DbTables.activity, where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete(DbTables.emergencyInfo, where: 'family_id = ?', whereArgs: [familyId]);

      final now = DateTime.now();

      // 1. Family Space
      await txn.insert(DbTables.families, {
        'id': familyId,
        'name': familyName,
        'invite_code': inviteCode,
        'created_by_id': userRahulId,
        'created_at': now.subtract(const Duration(days: 45)).millisecondsSinceEpoch,
      });

      // 2. Members
      await txn.insert(DbTables.members, {
        'id': 'demo-member-ramesh',
        'family_id': familyId,
        'name': 'Ramesh Sharma',
        'phone': '+91 98765 11111',
        'role': 'delegate', // Care Recipient / Elder
      });
      await txn.insert(DbTables.members, {
        'id': userRahulId,
        'family_id': familyId,
        'name': userRahulName,
        'phone': userRahulPhone,
        'role': 'admin',
      });
      await txn.insert(DbTables.members, {
        'id': 'demo-member-priya',
        'family_id': familyId,
        'name': 'Priya (Jaipur)',
        'phone': '+91 98765 22222',
        'role': 'caregiver',
      });
      await txn.insert(DbTables.members, {
        'id': 'demo-member-sunita',
        'family_id': familyId,
        'name': 'Sunita (Nurse)',
        'phone': '+91 98765 33333',
        'role': 'caregiver',
      });
      await txn.insert(DbTables.members, {
        'id': 'demo-member-ankit',
        'family_id': familyId,
        'name': 'Ankit (Relative)',
        'phone': '+91 98765 44444',
        'role': 'viewer',
      });

      // 3. Emergency Information
      await txn.insert(DbTables.emergencyInfo, {
        'family_id': familyId,
        'blood_group': 'B+',
        'allergies': 'Penicillin, Sulfa drugs',
        'conditions': 'Hypertension, Type 2 Diabetes, Mild Arthritis',
        'emergency_contact_name': 'Priya Sharma (Jaipur)',
        'emergency_contact_phone': '+91 98765 22222',
        'hospital': 'Fortis Escorts Hospital, Jaipur',
        'doctor_contact': 'Dr. Mehta (Cardiology) - +91 98111 22334',
      });

      // 4. Medicines
      // Telmisartan: only 4 tablets left (daily usage 1, threshold 7 -> 4 days left!)
      await txn.insert(DbTables.medicines, {
        'id': 'med-telmisartan',
        'family_id': familyId,
        'name': 'Telmisartan (Telma 40)',
        'schedule_note': '1 tablet daily after breakfast',
        'quantity_on_hand': 4,
        'daily_usage': 1,
        'refill_threshold_days': 7,
      });
      await txn.insert(DbTables.medicines, {
        'id': 'med-metformin',
        'family_id': familyId,
        'name': 'Metformin 500mg (Glycomet)',
        'schedule_note': '1 tablet after dinner',
        'quantity_on_hand': 36,
        'daily_usage': 2,
        'refill_threshold_days': 7,
      });
      await txn.insert(DbTables.medicines, {
        'id': 'med-atorvastatin',
        'family_id': familyId,
        'name': 'Atorvastatin 10mg (Atorva)',
        'schedule_note': '1 tablet at bedtime',
        'quantity_on_hand': 25,
        'daily_usage': 1,
        'refill_threshold_days': 7,
      });
      await txn.insert(DbTables.medicines, {
        'id': 'med-calcium',
        'family_id': familyId,
        'name': 'Calcium + Vit D3 (Shelcal 500)',
        'schedule_note': '1 tablet after lunch',
        'quantity_on_hand': 12,
        'daily_usage': 1,
        'refill_threshold_days': 5,
      });

      // 5. Tasks (2 Done, 2 Pending = 50% matching mockup)
      await txn.insert(DbTables.tasks, {
        'id': 'task-bp-check',
        'family_id': familyId,
        'title': 'Morning BP & vitals check',
        'description': 'Recorded 124/82 mmHg, Pulse 72',
        'due_at': DateTime(now.year, now.month, now.day, 8, 30).millisecondsSinceEpoch,
        'assignee_id': 'demo-member-sunita',
        'status': 'done',
        'recurrence': 'daily',
        'completed_by_id': 'demo-member-sunita',
        'completed_at': DateTime(now.year, now.month, now.day, 8, 45).millisecondsSinceEpoch,
      });
      await txn.insert(DbTables.tasks, {
        'id': 'task-morning-meds',
        'family_id': familyId,
        'title': 'Give Telmisartan 40mg after breakfast',
        'description': 'Take with lukewarm water',
        'due_at': DateTime(now.year, now.month, now.day, 9, 0).millisecondsSinceEpoch,
        'assignee_id': 'demo-member-priya',
        'status': 'done',
        'recurrence': 'daily',
        'completed_by_id': 'demo-member-priya',
        'completed_at': DateTime(now.year, now.month, now.day, 9, 10).millisecondsSinceEpoch,
      });
      await txn.insert(DbTables.tasks, {
        'id': 'task-evening-walk',
        'family_id': familyId,
        'title': 'Evening park walk (20 mins gentle stroll)',
        'description': 'Wear walking shoes with support',
        'due_at': DateTime(now.year, now.month, now.day, 17, 30).millisecondsSinceEpoch,
        'assignee_id': 'demo-member-priya',
        'status': 'todo',
        'recurrence': 'daily',
      });
      await txn.insert(DbTables.tasks, {
        'id': 'task-refill-telma',
        'family_id': familyId,
        'title': 'Order Refill: Telmisartan (Telma 40)',
        'description': '4 days of stock left. Order 1 month supply (30 tabs).',
        'due_at': DateTime(now.year, now.month, now.day, 19, 0).millisecondsSinceEpoch,
        'assignee_id': userRahulId,
        'status': 'todo',
        'recurrence': 'none',
      });

      // 6. Care Records
      await txn.insert(DbTables.records, {
        'id': 'rec-cardio',
        'family_id': familyId,
        'title': 'Cardiology Consultation & ECG Report',
        'date': now.subtract(const Duration(days: 7)).millisecondsSinceEpoch,
        'type': 'labReport',
        'tags': 'cardiology,ecg,dr-mehta',
        'visibility': 'family',
        'uploader_id': userRahulId,
      });
      await txn.insert(DbTables.records, {
        'id': 'rec-diabetes',
        'family_id': familyId,
        'title': 'HbA1c & Fasting Blood Sugar Test',
        'date': now.subtract(const Duration(days: 18)).millisecondsSinceEpoch,
        'type': 'labReport',
        'tags': 'diabetes,lab,hba1c',
        'visibility': 'family',
        'uploader_id': 'demo-member-priya',
      });
      await txn.insert(DbTables.records, {
        'id': 'rec-rx-slip',
        'family_id': familyId,
        'title': 'Prescription Slip - Dr. Mehta (Cardiology)',
        'date': now.subtract(const Duration(days: 25)).millisecondsSinceEpoch,
        'type': 'prescription',
        'tags': 'prescription,telma,glycomet',
        'visibility': 'caregivers',
        'uploader_id': userRahulId,
      });

      // 7. Activity Log (Shared Care)
      await txn.insert(DbTables.activity, {
        'id': 'act-1',
        'family_id': familyId,
        'actor_id': 'demo-member-sunita',
        'action': 'recorded vitals: BP 124/82, Pulse 72',
        'target_ref': 'task',
        'at': DateTime(now.year, now.month, now.day, 8, 45).millisecondsSinceEpoch,
      });
      await txn.insert(DbTables.activity, {
        'id': 'act-2',
        'family_id': familyId,
        'actor_id': 'demo-member-priya',
        'action': 'gave morning BP meds to Papa',
        'target_ref': 'task',
        'at': DateTime(now.year, now.month, now.day, 9, 10).millisecondsSinceEpoch,
      });
      await txn.insert(DbTables.activity, {
        'id': 'act-3',
        'family_id': familyId,
        'actor_id': userRahulId,
        'action': 'scheduled cardiology follow-up with Dr. Mehta',
        'target_ref': 'appointment',
        'at': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
      });
    });
  }

  /// Seeds demo data through Riverpod ref and refreshes providers.
  static Future<void> seed(WidgetRef ref) async {
    final db = await ref.read(appDatabaseProvider.future);
    await seedDirect(db);

    ref.invalidate(currentUserProvider);
    ref.invalidate(familySpaceProvider);
    ref.invalidate(membersProvider);
    ref.invalidate(tasksProvider);
    ref.invalidate(recordsProvider);
    ref.invalidate(medicinesProvider);
    ref.invalidate(emergencyInfoProvider);
    ref.invalidate(activityProvider);
  }

  /// Clears demo data and user session so the user can start fresh or manual setup.
  static Future<void> clearAll(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_user_id');
    await prefs.remove('local_user_name');
    await prefs.remove('local_user_phone');

    final db = await ref.read(appDatabaseProvider.future);
    await db.transaction((txn) async {
      await txn.delete(DbTables.families);
      await txn.delete(DbTables.members);
      await txn.delete(DbTables.tasks);
      await txn.delete(DbTables.medicines);
      await txn.delete(DbTables.records);
      await txn.delete(DbTables.activity);
      await txn.delete(DbTables.emergencyInfo);
    });

    ref.invalidate(currentUserProvider);
    ref.invalidate(familySpaceProvider);
    ref.invalidate(membersProvider);
    ref.invalidate(tasksProvider);
    ref.invalidate(recordsProvider);
    ref.invalidate(medicinesProvider);
    ref.invalidate(emergencyInfoProvider);
    ref.invalidate(activityProvider);
  }
}
