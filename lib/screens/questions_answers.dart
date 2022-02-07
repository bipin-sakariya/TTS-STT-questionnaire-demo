import 'package:flutter/material.dart';
import 'package:voiceMobileApp/screens/questionsManage.dart';

class QuestionsAnswers extends StatefulWidget {
  QuestionsAnswers({Key key}) : super(key: key);

  @override
  _QuestionsAnswersState createState() => _QuestionsAnswersState();
}

class _QuestionsAnswersState extends State<QuestionsAnswers> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to Questions and Answers MVP",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              margin: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
              child: RaisedButton(
                color: Colors.blue,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return QuestionsManage();
                    },
                  ));
                },
                child: Container(
                  height: 50.0,
                  alignment: Alignment.center,
                  child: Text(
                    "Start",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
