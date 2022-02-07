import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voiceMobileApp/fileHandling.dart';
import 'dart:developer' as developer;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class FileContent extends StatefulWidget {
  FileContent({Key key}) : super(key: key);

  @override
  _FileContentState createState() => _FileContentState();
}

class _FileContentState extends State<FileContent> {
  String fileContent = "";
  SharedPreferences prefs;
  String path = "";
  final pdf = pw.Document();
  Widget pdfFile;
  File file;

  @override
  void initState() {
    super.initState();
    getFileContent();
  }

  getFileContent() async {
    prefs = await SharedPreferences.getInstance();
    FileHandling.readFromFile().then((value) {
      developer.log(value, name: "Reading from file");
      setState(() {
        fileContent = value;
        path = prefs.getString('path');
      });
    }).whenComplete(() {
      getPdfFromFileData();
    });
  }

  getPdfFromFileData() async {
    Uint8List uint8list = await generateDocument();
    Directory output = await getTemporaryDirectory();
    file = File(output.path + "/example.pdf");
    setState(() {
      file.writeAsBytes(uint8list);
      print(file.path);
    });
  }

  Future<Uint8List> generateDocument() async {
    final pw.Document doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat:
            PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Table.fromTextArray(
              context: context,
              border: null,
              headerAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                [
                  fileContent,
                ]
              ],
            ),
            pw.Paragraph(text: ""),
            pw.Padding(padding: const pw.EdgeInsets.all(10)),
          ];
        },
      ),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Document"),
      ),
      body: file != null
          ? Container(
              child: Stack(
                children: [
                  PDFView(
                    filePath: file.path,
                    autoSpacing: false,
                    pageFling: false,
                  ),
                  Positioned(
                    bottom: 0.0,
                    right: 0.0,
                    child: Container(
                      height: 50.0,
                      width: 50.0,
                      margin: EdgeInsets.fromLTRB(0.0, 0.0, 20.0, 20.0),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      alignment: Alignment.center,
                      child: IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.description),
                        onPressed: () {
                          OpenFile.open(path);
                        },
                      ),
                    ),
                  )
                ],
              ),
            )
          : Container(),
    );
  }
}
