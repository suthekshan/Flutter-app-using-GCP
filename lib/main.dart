import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:html/parser.dart' as html_parser;

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Prediction App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  final picker = ImagePicker();
  String _prediction = '';
  String _percentage = '';
  String _error = '';

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> uploadImage(File image) async {
    final uri = Uri.parse('https://flask-docker-lgcs2dkt6a-uc.a.run.app/upload');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('photo', image.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();

        // Log the HTML response
        print('HTML Response: $responseData');

        // Parse the HTML response
        var document = html_parser.parse(responseData);
        var pElements = document.querySelectorAll('p');
        if (pElements.length >= 2) {
          var predictionElement = pElements[0].querySelector('strong');
          var percentageElement = pElements[1].querySelector('strong');

          if (predictionElement != null && percentageElement != null) {
            setState(() {
              _prediction = predictionElement.text;
              _percentage = percentageElement.text;
              _error = '';
            });
          } else {
            setState(() {
              _error = 'Could not find prediction or percentage in the response.';
            });
          }
        } else {
          setState(() {
            _error = 'Could not find enough <p> elements in the response.';
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error uploading image: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dog-Cat Classification APP'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: getImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_image != null) {
                  uploadImage(_image!);
                }
              },
              child: Text('Upload Image'),
            ),
            SizedBox(height: 20),
            Text('Prediction: $_prediction'),
            Text('Probability: $_percentage'),
            if (_error.isNotEmpty) ...[
              SizedBox(height: 20),
              Text('Error: $_error', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
