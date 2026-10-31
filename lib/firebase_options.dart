import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public Firebase client configuration. Passwords are entered at sign-in.
class DefaultFirebaseOptions {
  static const databaseUrl =
      'https://radiant-3bc0d-default-rtdb.asia-southeast1.firebasedatabase.app';
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Radiant currently supports Android and web.');
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyBijc1X-JRFdOg9FjgtU1u_C7jplPPOuHk',
    appId: '1:634213951024:web:b0ffe553500689ecaceff5',
    messagingSenderId: '634213951024',
    projectId: 'radiant-3bc0d',
    authDomain: 'radiant-3bc0d.firebaseapp.com',
    databaseURL: databaseUrl,
    storageBucket: 'radiant-3bc0d.firebasestorage.app',
  );
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBijc1X-JRFdOg9FjgtU1u_C7jplPPOuHk',
    appId: '1:634213951024:android:d89993aafe4c874caceff5',
    messagingSenderId: '634213951024',
    projectId: 'radiant-3bc0d',
    databaseURL: databaseUrl,
    storageBucket: 'radiant-3bc0d.firebasestorage.app',
  );
}
