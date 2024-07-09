import 'package:flutter/material.dart';
import '../widget/videoPlayer.dart';
import '../widget/leftItems.dart';
import '../widget/rightItems.dart';

class TikTokVideo extends StatelessWidget {
  final Map<String, dynamic> data;

  const TikTokVideo({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          TikTokVideoPlayer(url: data['url']),
          title(),
          RightItems(
            comments: data['commentCount'].toString(),
            // userImg: data['userImg'],
            favorite: data['favorite'],
            // coverImg: data['coverImg'],
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
