import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:proyectocomparador/routes/app_routes.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseOk = false;
  String? error;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseOk = true;
  } on FirebaseException catch (e) {
    firebaseOk = false;
    error = 'FirebaseException: ${e.code} - ${e.message}';
  } catch (e) {
    firebaseOk = false;
    error = e.toString();
  }

  runApp(MyApp(firebaseOk: firebaseOk, error: error));
}

class MyApp extends StatefulWidget {
  final bool firebaseOk;
  final String? error;

  const MyApp({super.key, required this.firebaseOk, this.error});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Carlos paginas',
      home: widget.firebaseOk
          ? null
          : Scaffold(
              appBar: AppBar(title: const Text("Firebase Error")),
              body: Center(
                child: Text(
                  "error\n${widget.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
      initialRoute: widget.firebaseOk ? AppRoutes.iniciarSesion : null,
      routes: AppRoutes.routes,
    );
  }
}
