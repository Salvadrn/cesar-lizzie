// File generated manually from GoogleService-Info.plist
// FlutterFire configuration for NeuroNav
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCj7iCIAbixy31vgG-WD0X60SExVj4Y9HU',
    appId: '1:1024737520355:ios:af11c130286f625dd273d6',
    messagingSenderId: '1024737520355',
    projectId: 'neuronav-b427f',
    storageBucket: 'neuronav-b427f.firebasestorage.app',
    iosBundleId: 'com.neuronav.neuronavApp',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuD6l5A-8EqvJLUBPSjGfzG0kMjix-IPU',
    appId: '1:1024737520355:android:fb1d500c8c4dc2aed273d6',
    messagingSenderId: '1024737520355',
    projectId: 'neuronav-b427f',
    storageBucket: 'neuronav-b427f.firebasestorage.app',
  );

  // TODO: Agregar google-services.json y actualizar estos valores
}