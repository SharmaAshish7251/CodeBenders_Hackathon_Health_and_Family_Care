// File generated based on google-services.json for healthandfamilycare.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqgfGCgE5VJBu6FtusFH-DXMn5wmKXFKI',
    appId: '1:845671542989:android:c205bb4c2eef611fd8b984',
    messagingSenderId: '845671542989',
    projectId: 'healthandfamilycare',
    storageBucket: 'healthandfamilycare.firebasestorage.app',
  );
}
