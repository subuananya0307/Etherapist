import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import 'after_session.dart';

class WebViewScreen2 extends StatefulWidget {
  @override
  _WebViewScreen2State createState() => _WebViewScreen2State();
}

class _WebViewScreen2State extends State<WebViewScreen2> {
  late final WebViewController _controller;
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  bool isLoading = true;
  bool _isRecording = false;
  String? _filePath;
  String _response = '';

  @override
  void initState() {
    super.initState();
    _initPermissions();
    _initWebView();
    _initializeRecorder();
  }

  Future<void> _initPermissions() async {
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }

    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    } else {
      await Permission.storage.request();
    }

    if (await Permission.microphone.isDenied ||
        (Platform.isAndroid && await Permission.manageExternalStorage.isDenied)) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text('Please allow all permissions from settings to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => isLoading = true),
          onPageFinished: (_) => setState(() => isLoading = false),
        ),
      )
      ..loadFlutterAsset('lib/images/interview.html');
  }

  Future<void> _initializeRecorder() async {
    try {
      await _audioRecorder.openRecorder();
    } catch (e) {
      print('Failed to initialize recorder: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_audioRecorder.isStopped) {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/audio_recording.aac'; // use AAC first for test

      try {
        await _audioRecorder.startRecorder(
          toFile: tempPath,
          codec: Codec.aacADTS, // <-- use AAC
          audioSource: AudioSource.microphone,
        );

        // Wait a little to make sure recorder actually starts
        await Future.delayed(Duration(milliseconds: 500));

        setState(() {
          _isRecording = true;
          _filePath = tempPath;
        });
        print('Recording started...');
      } catch (e) {
        print('Failed to start recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_audioRecorder.isStopped) {
      try {
        final path = await _audioRecorder.stopRecorder();
        setState(() => _isRecording = false);

        if (path != null) {
          File recordedFile = File(path);
          int fileSize = await recordedFile.length();

          if (fileSize > 1000) { // Ensure file size is more than 1KB
            await _saveToLocalStorage();
            await _uploadAudio();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recording too short.')),
            );
            print('Recording too short: $fileSize bytes');
          }
        }
      } catch (e) {
        print('Failed to stop recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording')),
        );
      }
    }
  }

  Future<void> _saveToLocalStorage() async {
    if (_filePath != null) {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir != null) {
        final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
        final savedFilePath = '${downloadsDir.path}/$fileName';

        File tempFile = File(_filePath!);
        await tempFile.copy(savedFilePath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording saved: $savedFilePath')),
        );
        print('Saved File Path: $savedFilePath');
      }
    }
  }

  Future<void> _uploadAudio() async {
    if (_filePath == null) {
      setState(() {
        _response = "No audio file selected!";
      });
      return;
    }

    var url = Uri.parse('http://192.168.135.254:5000/analyze');

    var request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath(
        'audio',
        _filePath!,
        contentType: MediaType('audio', 'aac'),
      ));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print("Response from server: $responseBody");

        setState(() {
          _response = responseBody;
        });

        // 👇 Navigate to AfterSession and pass the response
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AfterSession(apiResponse: responseBody),
          ),
        );

      } else {
        setState(() {
          _response = 'Failed to upload file! Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }


  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interview Session'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            Center(child: CircularProgressIndicator()),

          Positioned(
            bottom: 140,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _controller.runJavaScript(
                    "document.querySelector('a-scene')?.enterVR();"
                );
              },
              backgroundColor: Colors.blue,
              child: Icon(Icons.vrpano, color: Colors.white, size: 28),
            ),
          ),

          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _isRecording ? _stopRecording() : _startRecording();
              },
              backgroundColor: _isRecording ? Colors.red : Colors.green,
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AfterSession(apiResponse: _response),
                    ),
                  );

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'End Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'K2D',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}





//
//
//
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// import 'after_session.dart';
//
// class WebViewScreen2 extends StatefulWidget {
//   @override
//   _WebViewScreen2State createState() => _WebViewScreen2State();
// }
//
// class _WebViewScreen2State extends State<WebViewScreen2> {
//   late final WebViewController _controller;
//   bool isLoading = true; // For loading indicator
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (_) => setState(() => isLoading = true),
//           onPageFinished: (_) => setState(() => isLoading = false),
//         ),
//       )
//       ..loadFlutterAsset('lib/images/new.html'); // Ensure correct path
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: () => _controller.reload(),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (isLoading) Center(child: CircularProgressIndicator()),
//
//           // VR Button (Floating in Bottom-Right)
//           Positioned(
//             bottom: 80,
//             right: 20,
//             child: FloatingActionButton(
//               onPressed: () {
//                 _controller.runJavaScript("document.querySelector('a-scene').enterVR();");
//               },
//               backgroundColor: Colors.blue,
//               child: Icon(Icons.vrpano, color: Colors.white, size: 28),
//             ),
//           ),
//
//           Positioned(
//             bottom: 20, // Keep button at the bottom
//             left: 0,
//             right: 0,
//             child: Center(
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(builder: (context) => AfterSession()),
//                   );
//                   ; // Closes WebViewScreen
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red[400],
//                   padding: EdgeInsets.symmetric(horizontal: 25, vertical: 9),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: Text(
//                   'End Session',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontFamily: 'K2D',
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
// // import 'package:app/pages/after_session.dart';
// // import 'package:flutter/material.dart';
// //
// // class VrPage2 extends StatefulWidget {
// //   @override
// //   State<VrPage2> createState() => _VrPageState2();
// // }
// //
// // class _VrPageState2 extends State<VrPage2> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Stack(
// //         children: <Widget>[
// //           // Background Image
// //           Container(
// //             width: double.infinity,
// //             height: double.infinity,
// //             decoration: BoxDecoration(
// //               image: DecorationImage(
// //                 image: AssetImage('lib/images/public.jpg'),
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //           ),
// //           // "Please look at the screen" Text positioned over the image
// //           Positioned(
// //             top: 194,
// //             left: 80,
// //             child: Text(
// //               'Please look at the screen',
// //               textAlign: TextAlign.left,
// //               style: TextStyle(
// //                 color: Color.fromRGBO(0, 0, 0, 1),
// //                 fontFamily: 'K2D',
// //                 fontSize: 24,
// //                 letterSpacing: 0,
// //                 fontWeight: FontWeight.normal,
// //                 height: 1,
// //               ),
// //             ),
// //           ),
// //           // Top part with eTherapist text
// //
// //           // "End Session" Button at the bottom
// //           Positioned(
// //             bottom: 30,  // position it at the bottom with some margin
// //             left: 147,  // center the button horizontally
// //             child: TextButton(
// //               onPressed: () {
// //                 // Navigate to a new page when clicked
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(builder: (context) => AfterSession()),
// //                 );
// //               },
// //               style: TextButton.styleFrom(
// //                 backgroundColor: Color.fromRGBO(0, 0, 0, 0.72),
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(50),
// //                 ),
// //                 minimumSize: Size(135, 39),
// //               ),
// //               child: Text(
// //                 'End Session',
// //                 style: TextStyle(
// //                   color: Color.fromRGBO(246, 245, 245, 1),
// //                   fontFamily: 'K2D',
// //                   fontSize: 20,
// //                   letterSpacing: 0,
// //                   fontWeight: FontWeight.normal,
// //                   height: 1,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
