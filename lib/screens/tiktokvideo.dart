import 'package:flutter/material.dart';
import '../widget/videoPlayer.dart';
import '../widget/leftItems.dart';
import '../widget/rightItems.dart';
import '../widget/arScreen.dart';

class TikTokVideo extends StatelessWidget {
  final Map<String, dynamic> data;

  const TikTokVideo({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          if (data['type'] == 'video')
            TikTokVideoPlayer(url: data['url'])
          else
            ARScreen(modelPath: data['url']),
          title(),
          RightItems(
            comments: data['commentCount'].toString(),
            favorite: data['favorite'],
          ),
          LeftItems(
            description: data['description'],
            musicName: data['musicName'],
            authorName: data['authorName'],
            userName: data['userName'],
          )
        ],
      ),
    );
  }

  Widget title() => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28.0),
          child: Text(
            "Trending | For You",
            style: TextStyle(color: Colors.white, fontSize: 19.0),
          ),
        ),
      );
}
