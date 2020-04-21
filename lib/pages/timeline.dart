import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final usersRef = Firestore.instance.collection("users");

class Timeline extends StatefulWidget {
  final String currentUser;
  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts = [];
  List<String> following = [];
  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getFollowing() async {
    QuerySnapshot followingSnapshot = await followingRef
        .document(widget.currentUser)
        .collection("userFollowing")
        .getDocuments();
    List<String> ids =
        followingSnapshot.documents.map((doc) => doc.documentID).toList();
    setState(() {
      this.following = ids;
    });
  }

  getTimeline() async {
    print(widget.currentUser);
    QuerySnapshot docs = await timelineRef
        .document(widget.currentUser)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();

    List<Post> firebasePosts = [];
    print(docs.documents);
    firebasePosts = docs.documents
        .map((doc) => Post.fromDocument(doc))
        .toList();

    setState(() {
      this.posts = firebasePosts;
    });
  }

  buildTimeline() {
    print(posts);
    if (posts == null) {
      return Center(child: CircularProgressIndicator());
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(
        children: posts,
      );
    }
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream:
          usersRef.orderBy("timestamp", descending: true).limit(30).snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        List<UserResult> users = [];
        snapshot.data.documents.forEach((doc) {
          if (doc.exists) {
            User user = User.fromDocument(doc);
            bool isOwner = currentUser.id == user.id;
            bool isFollowing = following.contains(user.id);
            if (isOwner || isFollowing) {
              return;
            } else {
              UserResult userResult = UserResult(user);
              users.add(userResult);
            }
          }
        });
        return Container(
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size: 30.0,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      "Users To Follow",
                      style: TextStyle(
                          fontSize: 30, color: Theme.of(context).primaryColor),
                    )
                  ],
                ),
              ),
              Column(
                children: users,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
          onRefresh: () => getTimeline(),
          child: Container(
            padding: EdgeInsets.only(top: 10,bottom: 30),
            child: buildTimeline(),
          )),
    );
  }
}
