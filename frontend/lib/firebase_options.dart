// File generated for Firebase initialization in Heathify
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAq7UcYgAjVcYW9K3nM53g5HndzjVhJCgo',
    appId: '1:684483169008:web:66488bafd2ec053aedd035',
    messagingSenderId: '684483169008',
    projectId: 'health-97e8d',
    authDomain: 'health-97e8d.firebaseapp.com',
    storageBucket: 'health-97e8d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAq7UcYgAjVcYW9K3nM53g5HndzjVhJCgo',
    appId: '1:684483169008:android:66488bafd2ec053aedd035',
    messagingSenderId: '684483169008',
    projectId: 'health-97e8d',
    storageBucket: 'health-97e8d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAq7UcYgAjVcYW9K3nM53g5HndzjVhJCgo',
    appId: '1:684483169008:ios:66488bafd2ec053aedd035',
    messagingSenderId: '684483169008',
    projectId: 'health-97e8d',
    storageBucket: 'health-97e8d.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAq7UcYgAjVcYW9K3nM53g5HndzjVhJCgo',
    appId: '1:684483169008:ios:66488bafd2ec053aedd035',
    messagingSenderId: '684483169008',
    projectId: 'health-97e8d',
    storageBucket: 'health-97e8d.firebasestorage.app',
  );
}

