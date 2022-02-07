import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:voiceMobileApp/element/common.dart';
import 'dart:developer' as developer;

import 'package:voiceMobileApp/screens/questions_answers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  isNetworkAvailable().then((value) {
    if (value) {
      developer.log("Internet is available");
    } else {
      developer.log("Internet is not available");
    }
  });
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: QuestionsAnswers(),
    );
  }
}
