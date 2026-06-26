import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializace Hive pro lokální úložiště relací
  await Hive.initFlutter();
  // Registrace adapterů by zde byla v plné verzi s hive_generator

  runApp(
    const ProviderScope(
      child: PhoneRoomSlamApp(),
    ),
  );
}
