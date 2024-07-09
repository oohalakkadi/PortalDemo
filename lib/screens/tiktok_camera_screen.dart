import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'portal_camera_screen.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';

class TikTokCameraScreen extends StatefulWidget {
  @override
  _TikTokCameraScreenState createState() => _TikTokCameraScreenState();
}

class _TikTokCameraScreenState extends State<TikTokCameraScreen> {
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
    if (_controller == null || !_controller!.value.isInitialized || !_controller!.value.isRecordingVideo) {
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

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      final videoFile = File(result.files.single.path!);
      _uploadVideo(videoFile);
      print('Video selected: ${videoFile.path}');
    }
  }

  Future<void> _uploadVideo(File videoFile) async {
    if (!videoFile.existsSync()) {
      print('Error: File does not exist at path ${videoFile.path}');
      return;
    }
    try {
      final storageRef = FirebaseStorage.instance.ref().child('videos/${videoFile.path.split('/').last}');
      final uploadTask = storageRef.putFile(videoFile);
      final snapshot = await uploadTask;
      final videoUrl = await snapshot.ref.getDownloadURL();
      print('Video uploaded: $videoUrl');
      await FirebaseFirestore.instance.collection('videos').add({
        'url': videoUrl,
        'timestamp': Timestamp.now(),
        "commentCount": Random().nextInt(100) + 1,
        // "userImg": "https://storage.googleapis.com/portals-ce599.appspot.com/assets/Compressed.JPG",
        "favorite": Random().nextInt(100) + 1,
        // "coverImg": "https://storage.googleapis.com/portals-ce599.appspot.com/assets/FINALGIF.gif",
        "description": "This is a sample video.",
        "musicName": "Sample Music",
        "authorName": "Sample Author",
        "userName": "ooha123",
      });
      // Show a popup notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your video has been uploaded successfully!')),
      );
    } catch (e) {
      print('Error uploading video: $e');
    }
  }

  void _processVideo() async {
    print('Processing video...');
    if (_videoPath != null) {
      final videoFile = File(_videoPath!);
      if (!videoFile.existsSync()) {
        print('Error: Recorded file does not exist at path $_videoPath');
        return;
      }
      _uploadVideo(videoFile);
      print('Video path: $_videoPath');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to the Portal Camera screen
              // Replace `PortalCameraScreen` with the actual screen for the portal camera
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PortalCameraScreen()),
              );
            },
            child: Text(
              'Switch to Portal Camera',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
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
                            onPressed: _pickVideo,
                          ),
                          FloatingActionButton(
                            onPressed: _isRecording ? _stopRecording : _startRecording,
                            child: Icon(_isRecording ? Icons.stop : Icons.videocam),
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
