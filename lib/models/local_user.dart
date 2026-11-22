import 'package:flutter/foundation.dart';

/// The signed-in user on this device. Created by the local sign-in stub.
@immutable
class LocalUser {
  const LocalUser({required this.id, required this.name, required this.phone});

  final String id;
  final String name;
  final String phone;
}
