import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tiktokvideo.dart'; // Ensure this import path is correct

class Trending extends StatefulWidget {
  @override
  _TrendingState createState() => _TrendingState();
}

class _TrendingState extends State<Trending> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      // Fetch videos
      QuerySnapshot videoSnapshot =
          await FirebaseFirestore.instance.collection('videos').get();
      List<Map<String, dynamic>> videoData = videoSnapshot.docs
          .map((doc) => {'type': 'video', ...doc.data() as Map<String, dynamic>})
          .toList();

      // Fetch AR models
      QuerySnapshot arSnapshot =
          await FirebaseFirestore.instance.collection('portals').get();
      List<Map<String, dynamic>> arData = arSnapshot.docs
          .map((doc) => {'type': 'ar', ...doc.data() as Map<String, dynamic>})
          .toList();

      // Combine and sort by timestamp or any other criteria
      List<Map<String, dynamic>> combinedData = [...videoData, ...arData];
      combinedData.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      if (mounted) {
        setState(() {
          _items = combinedData;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return TikTokVideo(data: _items[index]);
              },
            ),
    );
  }
}
