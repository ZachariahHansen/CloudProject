import 'package:flutter/material.dart';
// import 'package:cloud_project/features/screens/home/notifications/notificationsColumn.dart';
// import 'package:cloud_project/features/screens/home/posts/postsColumn.dart';

class GenerateHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        children: [
          Expanded(
            child: Container(
              // child: PostsColumn(),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.25,
            child: Container(
              color: Colors.white,
              //child: NotificationColumn(),
            ),
          )
        ],
      ),
    );
  }
}
