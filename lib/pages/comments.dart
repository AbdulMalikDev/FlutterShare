import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String mediaUrl;
  Comments({this.postId, this.ownerId, this.mediaUrl});

  @override
  CommentsState createState() => CommentsState(
        mediaUrl: this.mediaUrl,
        ownerId: this.ownerId,
        postId: this.postId,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  String mediaUrl;
  String postId;
  String ownerId;
  CommentsState({this.mediaUrl, this.ownerId, this.postId});

  buildComments() {
    return StreamBuilder(
      stream: commmentsRef
          .document(postId)
          .collection("comments")
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        List<Comment> comments = [];
        snapshot.data.documents.forEach((doc) {
          comments.add(Comment.from(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  addComment() {
    commmentsRef.document(postId).collection("comments").add({
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": DateTime.now(),
      "avatarUrl": currentUser.photoUrl,
      "userId": ownerId
    });
    bool isOwner = currentUser.id == ownerId;
     if(!isOwner)
     {

     activityFeedRef.document(ownerId).collection("feedItems").add({
       "type" : "comment",
        "username" : currentUser.username,
        "userId" : currentUser.id,
        "userProfileImg" : currentUser.photoUrl,
        "postId" : postId,
        "mediaUrl" : mediaUrl,
        "timestamp" : DateTime.now(),

     });
     }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(
            child: buildComments(),
          ),
          Divider(),
          ListTile(
            title: TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: "Enter your comment...",
              ),
            ),
            trailing: OutlineButton(
              onPressed: () => addComment(),
              child: Text("POST"),
              borderSide: BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  String username;
  String comment;
  Timestamp timestamp;
  String avatarUrl;
  String userId;

  Comment({
    this.username,
    this.comment,
    this.timestamp,
    this.avatarUrl,
    this.userId,
  });

  factory Comment.from(doc) {
    return Comment(
      avatarUrl: doc["avatarUrl"],
      comment: doc["comment"],
      timestamp: doc["timestamp"],
      username: doc["username"],
      userId: doc["userId"],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            style: TextStyle(color: Colors.grey),
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.grey,
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
        ),
      ],
    );
  }
}
