import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:delayed_display/delayed_display.dart';

class RightItems extends StatelessWidget {
  final String? comments;
  final int? favorite;

  // Set the asset paths directly
  final String userImg = "assets/user.JPG";
  final String coverImg = "assets/music.gif";

  RightItems({this.comments, this.favorite});

  @override
  Widget build(BuildContext context) {
    final Random random = Random();
    final String displayComments = comments ?? random.nextInt(100).toString();
    final String displayFavorite = favorite?.toString() ?? random.nextInt(100).toString();

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(right: 8.0, bottom: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            DelayedDisplay(
              delay: Duration(milliseconds: 300),
              child: userAvatar(),
            ),
            SizedBox(height: 18.0),
            DelayedDisplay(
              delay: Duration(milliseconds: 400),
              child: actionButton(
                icon: FontAwesomeIcons.heart,
                count: displayFavorite,
                iconColor: Colors.red,
              ),
            ),
            SizedBox(height: 18.0),
            DelayedDisplay(
              delay: Duration(milliseconds: 500),
              child: actionButton(
                icon: FontAwesomeIcons.comment,
                count: displayComments,
              ),
            ),
            SizedBox(height: 18.0),
            DelayedDisplay(
              delay: Duration(milliseconds: 600),
              child: musicCover(),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton({IconData? icon, String? count, Color? iconColor}) {
    return Column(
      children: <Widget>[
        Icon(
          icon,
          size: 36.0,
          color: iconColor ?? Colors.white,
        ),
        SizedBox(height: 6.0),
        Text(
          count!,
          style: TextStyle(fontSize: 14.0, color: Colors.white),
        ),
      ],
    );
  }

  Widget userAvatar() {
    return Container(
      width: 50.0,
      height: 50.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(userImg),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget musicCover() {
    return CircleAvatar(
      backgroundColor: Colors.black,
      radius: 35.0,
      child: Container(
        width: 30.0,
        height: 30.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: AssetImage(coverImg),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
