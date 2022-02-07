import 'package:connectivity/connectivity.dart';

import 'package:flutter/material.dart';

// Check Internet connectivity
Future<bool> isNetworkAvailable() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile ||
      connectivityResult == ConnectivityResult.wifi) {
    return true;
  } else {
    return false;
  }
}

// Display Alert dialog box If no internet
alertDialogBox(BuildContext context, String errorMsg) {
  AlertDialog alertDialog = AlertDialog(
    title: Text("No Internet"),
    content: Container(
      child: Text(errorMsg),
    ),
    actions: [
      MaterialButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(
          "OK",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      )
    ],
  );

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return alertDialog;
    },
  );
}
