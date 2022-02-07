import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voiceMobileApp/element/common.dart';
import 'package:voiceMobileApp/fileHandling.dart';

import 'package:voiceMobileApp/model/questions.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voiceMobileApp/screens/fileContent.dart';

class QuestionsManage extends StatefulWidget {
  QuestionsManage({Key key}) : super(key: key);

  @override
  _QuestionsManageState createState() => _QuestionsManageState();
}

class _QuestionsManageState extends State<QuestionsManage> {
  List<Questions> questions = [];
  int currentIndex = 0;
  final focusNode = FocusNode();
  SharedPreferences prefs;
  bool isInternetAvailable = true;

  // Outside build method
  PageController pageController = PageController();
  var currentPage = 0.0;
  bool isLastPage = false;

  // Text to Speech
  bool isPlaying = false;
  FlutterTts _flutterTts;
  bool isSpeeching = false;

  // File Handling
  FileHandling fileHandling;

  // Speech to text
  SpeechToText _speechToText;
  double _confidence = 1.0;
  bool _isListening = false;
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    checkInternetConnectivity();
  }

  @override
  void dispose() {
    super.dispose();
    textController.dispose();
    // Speech to text dispose
    if (_speechToText != null) {
      _speechToText.cancel();
      _speechToText.stop();
    }
    // Text to speech dispose
    if (_flutterTts != null) {
      _flutterTts.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus) {
                  currentFocus.unfocus();
                }
              },
              child: _questionsManage(),
            ),
          ],
        ),
      ),
    );
  }

  _questionsManage() {
    return questions.isEmpty
        ? isInternetAvailable
            ? Container(
                margin: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 20.0),
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              )
            : Container(
                width: double.infinity,
                alignment: Alignment.center,
                //color: Colors.amber,
                child: Column(
                  children: [
                    Text(
                      "Internet not available!!",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        checkInternetConnectivity();
                      },
                    )
                  ],
                ),
              )
        : Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                      child: IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 0.0),
                      child: Text(
                        "Qustions & Answer",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
                height: MediaQuery.of(context).size.height / 1.2,
                child: PageView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  controller: pageController,
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListView(
                        children: [
                          Container(
                            child: _questions(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  _questions(int index) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
              width: double.infinity,
              child: Text(
                "Listen to Questions " + (index + 1).toString(),
                style: TextStyle(
                    color: Colors.black38, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              padding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Text(
                questions[index].question,
                style: TextStyle(
                  color: Colors.black45,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            isSpeeching ? Colors.black12 : Colors.transparent,
                        child: IconButton(
                          highlightColor: Colors.greenAccent,
                          icon: Icon(
                            isSpeeching ? Icons.pause : Icons.play_arrow,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            if (!isSpeeching) {
                              setState(() {
                                isSpeeching = true;
                                currentIndex = index;
                              });
                              _speak(questions[index].question);
                            }
                          },
                        ),
                      ),
                      Text(
                        "Play",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            questions[index].hasResponse ? _answer() : Container(),
          ],
        ),
      ],
    );
  }

  _answer() {
    return Container(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
            width: double.infinity,
            child: Text(
              "To respond, press the microphone icon...",
              style:
                  TextStyle(color: Colors.black38, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              color: Colors.amber,
            ),
            margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 15.0),
            child: TextFormField(
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: Colors.black,
              maxLines: 5,
              minLines: 2,
              controller: textController,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20.0),
                hintText: "Hold Voice icon for response",
                hintStyle: TextStyle(
                  color: Colors.black38,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onLongPressStart: (_) {
                      developer.log("Press");
                      _listen();
                    },
                    onLongPressUp: () {
                      setState(() {
                        _isListening = false;
                        if (_speechToText != null) {
                          _speechToText.cancel();
                          _speechToText.stop();
                        }
                      });
                      developer.log("Release");
                    },
                    child: CircleAvatar(
                      backgroundColor:
                          _isListening ? Colors.black12 : Colors.transparent,
                      child: IconButton(
                        highlightColor: Colors.blueAccent,
                        icon: Icon(
                          _isListening ? Icons.mic_off : Icons.mic,
                          color: Colors.blue,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  Text(
                    "Voice",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ],
          ),
          SizedBox(
            height: 15.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              textController.text.isNotEmpty
                  ? RaisedButton(
                      color: Colors.blue,
                      onPressed: () async {
                        setState(() {
                          if (textController.text.isNotEmpty) {
                            questions[currentIndex].answer =
                                textController.text;
                            developer.log(questions[currentIndex].answer,
                                name: "Answer $currentIndex");
                            questions[currentIndex].hasResponseSaved = true;
                            textController.clear();
                          }
                        });
                        // Move to next page after save
                        if (currentIndex != (questions.length - 1)) {
                          await Future.delayed(
                              const Duration(microseconds: 500), () {
                            pageController.animateToPage(currentIndex + 1,
                                duration: Duration(seconds: 1),
                                curve: Curves.easeInOut);
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            width: 5.0,
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20.0,
                          )
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          questions[currentIndex].hasResponseSaved
              ? Container(
                  margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isLastPage
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  child: Text(
                                    "Your questions and answers are saved!",
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Container(
                                  child: Text(
                                    "Thank you!!",
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.done,
                                  color: Colors.green,
                                ),
                                SizedBox(
                                  width: 5.0,
                                ),
                                Container(
                                  child: Text(
                                    "Your response is saved",
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                )
              : Container(),
          SizedBox(
            width: 10.0,
          ),
          isLastPage && questions[currentIndex].hasResponseSaved == true
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 50.0,
                    width: 50.0,
                    margin: EdgeInsets.fromLTRB(0.0, 0.0, 20.0, 0.0),
                    child: RaisedButton(
                      padding: EdgeInsets.all(0.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      color: Colors.blue,
                      onPressed: () {
                        _saveAnswersToFile();
                      },
                      child: Icon(
                        Icons.arrow_forward,
                        size: 20.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  // Create a work file and Save data into it
  _saveAnswersToFile() async {
    prefs = await SharedPreferences.getInstance();
    String data = "";
    File file;
    for (int i = 0; i < questions.length; i++) {
      data = data +
          "Questions " +
          (i + 1).toString() +
          " : " +
          questions[i].question.toString() +
          "\n" +
          "Response " +
          (i + 1).toString() +
          " : " +
          questions[i].answer.toString() +
          "\n\n";
    }
    // Add data to file & Retrive File
    FileHandling.saveToFile(data).then((value) {
      setState(() {
        file = value;
      });
    });
    // Read data from file & Open file
    FileHandling.readFromFile().then((value) {
      developer.log(value, name: "Reading from file");
    }).whenComplete(() {
      String path = prefs.getString('path');
      developer.log(path, name: "path");
      Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return FileContent();
        },
      ));
    });
  }

  // Speech to text
  void _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (val) => setState(() {
            textController.text = val.recognizedWords;
            developer.log(textController.text.toString());
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  // Text to Speech
  initializeTts() async {
    _flutterTts = FlutterTts();

    await _flutterTts.setLanguage("en-US");
    _flutterTts.setStartHandler(() {
      setState(() {
        isPlaying = true;
      });
    });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
        isSpeeching = false;
        questions[currentIndex].hasResponse = true;
      });
    });
    _flutterTts.setErrorHandler((err) {
      setState(() {
        print("error occurred: " + err);
        isPlaying = false;
      });
    });
  }

  Future _speak(String text) async {
    if (text != null && text.isNotEmpty) {
      var result = await _flutterTts.speak(text);
      if (result == 1)
        setState(() {
          isPlaying = true;
        });
    }
  }

  Future _stop() async {
    var result = await _flutterTts.stop();
    if (result == 1)
      setState(() {
        isPlaying = false;
      });
  }

  // Permission Handling
  void requestMicPermission() async {
    var status = await Permission.microphone.status;
    switch (status) {
      case PermissionStatus.permanentlyDenied:
        await hasGrantedPermission();
        developer.log('permanantly denied!', name: "Permission");
        break;
      case PermissionStatus.denied:
        await hasGrantedPermission();
        developer.log('denied!', name: "Permission");
        break;
      case PermissionStatus.undetermined:
        await hasGrantedPermission();
        developer.log('undetermined!', name: "Permission");
        break;
      case PermissionStatus.restricted:
        developer.log('permanantly denied!', name: "Permission");
        break;
      case PermissionStatus.granted:
        developer.log('Permission Granted!', name: "Permission");
        break;
    }
  }

  Future hasGrantedPermission() async {
    await Permission.microphone.request();
    await Permission.speech.request();
  }

  // Has Internet or not
  checkInternetConnectivity() async {
    isNetworkAvailable().then((value) {
      if (value) {
        getAllQuestionsfromFirebase();
      } else {
        setState(() {
          isInternetAvailable = value;
        });
      }
    });
  }

  // Firebase Handling
  getAllQuestionsfromFirebase() async {
    List<Questions> temp = [];

    await FirebaseFirestore.instance.collection('Question').get().then((value) {
      value.docs.forEach((element) {
        temp.add(
          new Questions(
            id: element.data()['id'].toString(),
            question: element.data()['question'].toString(),
            hasResponse: false,
            answer: "",
            hasResponseSaved: false,
          ),
        );
      });
      setState(() {
        questions = temp;
      });
      questions.forEach((element) {
        developer.log(element.question);
      });
    }).whenComplete(() {
      requestMicPermission();
      pageController.addListener(() {
        // Stop speech if user swipe
        isSpeeching = false;
        _stop();

        // get the current Index
        currentPage = pageController.page;
        setState(() {
          currentIndex = pageController.page.toInt();
          //textController.text = "";
        });

        // Last page for save file
        if (currentPage == (questions.length - 1)) {
          setState(() {
            isLastPage = true;
          });
        } else {
          setState(() {
            isLastPage = false;
          });
        }
      });
      // Init Text-to-Speech & Speech recognition
      initializeTts();
    });
  }
}
