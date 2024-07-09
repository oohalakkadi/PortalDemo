import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tiktokvideo.dart'; // Ensure this import path is correct

class Trending extends StatefulWidget {
  @override
  _TrendingState createState() => _TrendingState();
}

class _TrendingState extends State<Trending> {
  List<Map<String, dynamic>> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('videos').get();
      List<Map<String, dynamic>> videoData = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      if (mounted) {
        setState(() {
          _videos = videoData;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching videos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                return TikTokVideo(data: _videos[index]);
              },
            ),
    );
  }
}
