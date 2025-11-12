import 'package:flutter/material.dart';
import 'package:proyectocomparador/routes/app_routes.dart';
//import 'package:flutter_proyecto_final/moodels/pokemon.dart';
// 'package:flutter_proyecto_final/routes/app_routes.dart';
//mport 'package:firebase_core/firebase_core.dart';
//import 'package:flutter_proyecto_final/servicios/firebase.dart';
//import 'package:flutter_proyecto_final/servicios/pokemon_buscador.dart';
//import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
/*await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );*/

    runApp(const MyApp(firebaseOk: true));
  } catch (e) {
    runApp(MyApp(firebaseOk: false, error: e.toString()));
  }
}

class MyApp extends StatefulWidget {
  final bool firebaseOk;
  final String? error;

  const MyApp({super.key, required this.firebaseOk, this.error});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
//final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    inicializarApp();
  }

  void inicializarApp() async {
    if (widget.firebaseOk) {
      try {} catch (e) {
        //  print("Error : $e");
      }
    }
  }

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
