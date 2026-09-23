import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'frontend/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Por ahora la demo usa MockTalentRepository (datos locales).
  // Para conectar Firebase, después de `flutterfire configure`:
  //
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //   runApp(ProviderScope(
  //     overrides: [
  //       talentRepositoryProvider.overrideWithValue(
  //         FirestoreTalentRepository(FirebaseFirestore.instance),
  //       ),
  //     ],
  //     child: const PulsoApp(),
  //   ));
  runApp(const ProviderScope(child: PulsoApp()));
}
