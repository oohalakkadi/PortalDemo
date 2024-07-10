import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String LUMA_API_KEY = dotenv.env['LUMA_API_KEY'].toString();

class PortalCameraScreen extends StatefulWidget {
  @override
  _PortalCameraScreenState createState() => _PortalCameraScreenState();
}

class _PortalCameraScreenState extends State<PortalCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String? _videoPath;
  bool _isRecording = false;
  bool _noCamerasAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    print('Initializing camera...');
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('No cameras available');
        setState(() {
          _noCamerasAvailable = true;
        });
        return;
      }
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      if (mounted) {
        setState(() {
          print('Camera initialized successfully');
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _noCamerasAvailable = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    print('Starting recording...');
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Controller not initialized');
      return;
    }

    if (_controller!.value.isRecordingVideo) {
      print('Already recording video');
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final videoPath = join(directory.path, '${DateTime.now()}.mp4');
      await _controller!.startVideoRecording();
      setState(() {
        _videoPath = videoPath;
        _isRecording = true;
      });
      print('Recording started: $_videoPath');
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    print('Stopping recording...');
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_controller!.value.isRecordingVideo) {
      print('Controller not recording video');
      return;
    }

    try {
      final video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      print('Recording stopped: ${video.path}');
      setState(() {
        _videoPath = video.path;
      });

    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  void _processVideo() async {
    if (_videoPath != null) {
      print('Processing video at path: $_videoPath');
      final videoFile = File(_videoPath!);

      if (!videoFile.existsSync()) {
        print('Error: Recorded file does not exist at path $_videoPath');
        return;
      }

      try {
        // Create capture
        var captureData = await _createCapture();
        // Upload capture to API
        await _uploadCapture(captureData['signedUrls']['source'], videoFile);

        // Trigger video to model conversion
        await _triggerCapture(captureData['capture']['slug']);

        // Download capture (fetch the processed model URL)
        String modelUrl = await _getCapture(captureData['capture']['slug']);

        // Upload the model URL to Firebase
        await _uploadModel(modelUrl);

        // For now, just navigate back to the home screen
        Navigator.pop(context);
      } catch (e) {
        print('Error processing video: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _createCapture() async {
    var headers = {
      'Authorization':
          LUMA_API_KEY,
    };
    var request = http.Request('POST',
        Uri.parse('https://webapp.engineeringlumalabs.com/api/v2/capture'));
    request.bodyFields = {'title': Timestamp.now().toString()};
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final captureData = json.decode(responseBody);
      print('Capture Data: $captureData');
      return captureData;
    } else {
      print('Failed to create capture: ${response.reasonPhrase}');
      throw Exception('Failed to create capture');
    }
  }

  Future<void> _uploadCapture(String uploadUrl, File videoFile) async {
    var request = http.MultipartRequest('PUT', Uri.parse(uploadUrl));
    request.files
        .add(await http.MultipartFile.fromPath('file', videoFile.path));

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print('Video uploaded successfully');
    } else {
      print('Failed to upload video: ${response.statusCode}');
      throw Exception('Failed to upload video');
    }
  }

  Future<void> _triggerCapture(String slug) async {
    var headers = {
      'Authorization':
          LUMA_API_KEY,
    };
    var request = http.Request(
        'POST',
        Uri.parse(
            'https://webapp.engineeringlumalabs.com/api/v2/capture/$slug'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print('Capture processing triggered successfully');
    } else {
      print('Failed to trigger capture: ${response.statusCode}');
      throw Exception('Failed to trigger capture');
    }
  }

  Future<String> _getCapture(String slug) async {
  var headers = {
    'Authorization': LUMA_API_KEY,
  };

  while (true) {
    var response = await http.get(
      Uri.parse('https://webapp.engineeringlumalabs.com/api/v2/capture/$slug'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      print('Capture Data: $responseBody');

      // Check the status of the latest run
      if (responseBody['latestRun']['status'] == 'finished') {
        // Find the URL of the desired artifact type
        final artifacts = responseBody['latestRun']['artifacts'];
        final modelArtifact = artifacts.firstWhere((artifact) => artifact['type'] == 'textured_mesh_glb');
        final modelUrl = modelArtifact['url'];
        print('Model URL: $modelUrl');
        return modelUrl;
      } else {
        print('Capture not yet complete. Current status: ${responseBody['latestRun']['status']}');
      }
    } else {
      print('Failed to get capture: ${response.statusCode}');
      throw Exception('Failed to get capture');
    }

    // Wait for a while before checking again
    await Future.delayed(Duration(seconds: 10));
  }
}

  Future<void> _uploadModel(String modelUrl) async {
    try {
      final http.Response response = await http.get(Uri.parse(modelUrl));

      if (response.statusCode == 200) {
        final Directory tempDir = await getTemporaryDirectory();
        final File tempFile =
            File('${tempDir.path}/${DateTime.now().toIso8601String()}.glb');
        await tempFile.writeAsBytes(response.bodyBytes);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('3d_models/${DateTime.now().toIso8601String()}.glb');
        final uploadTask = storageRef.putFile(tempFile);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('3d_models').add({
          'url': downloadUrl,
          'timestamp': Timestamp.now(),
          "commentCount": Random().nextInt(100) + 1,
          // "userImg": "https://storage.googleapis.com/portals-ce599.appspot.com/assets/Compressed.JPG",
          "favorite": Random().nextInt(100) + 1,
          // "coverImg": "https://storage.googleapis.com/portals-ce599.appspot.com/assets/FINALGIF.gif",
          "description": "This is a Portal. Welcome to the future.",
          "musicName": "Sample Music",
          "authorName": "Sample Author",
          "userName": "ooha123",
        });

        print('Model uploaded to Firebase: $downloadUrl');
        
        // Make POST request to Flask server to process the model
        await _processModelOnServer(downloadUrl);

      } else {
        print('Failed to download model file: ${response.statusCode}');
        throw Exception('Failed to download model file');
      }
    } catch (e) {
      print('Error uploading model to Firebase: $e');
      throw Exception('Error uploading model to Firebase');
    }
  }

  Future<void> _processModelOnServer(String modelUrl) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5001/process_model'), 
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model_path': modelUrl,
        }),
      );

      if (response.statusCode == 200) {
        print('Model processing initiated successfully');
      } else {
        print('Failed to initiate model processing: ${response.statusCode}');
        throw Exception('Failed to initiate model processing');
      }
    } catch (e) {
      print('Error processing model on server: $e');
      throw Exception('Error processing model on server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Portal Camera'),
      ),
      body: _noCamerasAvailable
          ? Center(child: Text('No cameras available'))
          : (_controller == null || !_controller!.value.isInitialized)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        'Initializing camera...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    CameraPreview(_controller!),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.upload_file, color: Colors.white),
                            onPressed: _isRecording ? null : _processVideo,
                          ),
                          FloatingActionButton(
                            onPressed:
                                _isRecording ? _stopRecording : _startRecording,
                            child: Icon(
                                _isRecording ? Icons.stop : Icons.videocam),
                          ),
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.white),
                            onPressed: _processVideo,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
