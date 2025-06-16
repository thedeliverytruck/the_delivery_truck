// File: firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyALP_9OIY5UFIu4YnZLlWsD_QoePLNHc_w",
    authDomain: "the-delivery-truck-31813.firebaseapp.com",
    projectId: "the-delivery-truck-31813",
    storageBucket: "the-delivery-truck-31813.appspot.com",
    messagingSenderId: "783046945769",
    appId: "1:783046945769:web:49824e1d306dc3635cf978",
    measurementId: "G-N90DTV9ML8",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyALP_9OIY5UFIu4YnZLlWsD_QoePLNHc_w",
    appId: "1:783046945769:android:6150f776f8c95b185cf978",
    messagingSenderId: "783046945769",
    projectId: "the-delivery-truck-31813",
    storageBucket: "the-delivery-truck-31813.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyALP_9OIY5UFIu4YnZLlWsD_QoePLNHc_w",
    appId: "1:783046945769:ios:c27f9a54e22585be5cf978",
    messagingSenderId: "783046945769",
    projectId: "the-delivery-truck-31813",
    storageBucket: "the-delivery-truck-31813.appspot.com",
    iosBundleId: "com.billn.thedeliverytruck",
  );
}
