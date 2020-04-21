import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    // if no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // if the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String userId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;

  bool showHeart = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  buildLikeLogic() {
    isLiked = likes[userId] == true;
    if (isLiked) {
      postsRef
          .document(ownerId)
          .collection("userPosts")
          .document(postId)
          .updateData({"likes.$userId": false});
      //remove like from feed
      removeLikeFromFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[userId] = false;
      });
    } else if (!isLiked) {
      postsRef
          .document(ownerId)
          .collection("userPosts")
          .document(postId)
          .updateData({"likes.$userId": true});
      //update like in feed
      addLikeToFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[userId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToFeed() {
    bool isOwner = currentUser.id == ownerId;
    if (!isOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .setData({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": DateTime.now(),
      });
    }
  }

  removeLikeFromFeed() {
    bool isOwner = currentUser.id == ownerId;
    if (!isOwner) {
      activityFeedRef
          .document(ownerId)
          .collection("feedItems")
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUser.id == user.id;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(
              context,
              profileId: user.id,
            ),
            child: Text(
              user.username??"",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(Icons.delete),
                )
              : Text(""),
        );
      },
    );
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: () => buildLikeLogic(),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 400),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.easeInOutBack,
                  cycles: 0,
                  builder: (anim) => Transform.scale(
                      scale: anim.value,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.grey.withOpacity(0.6),
                        size: 150,
                      )),
                )
              : Text("")
        ],
      ),
    );
  }

  buildPostFooter() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
         if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
                GestureDetector(
                  onTap: () => buildLikeLogic(),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 28.0,
                    color: Colors.pink,
                  ),
                ),
                Padding(padding: EdgeInsets.only(right: 20.0)),
                GestureDetector(
                  onTap: () => showComments(context,
                      ownerId: ownerId, postId: postId, mediaUrl: mediaUrl),
                  child: Icon(
                    Icons.chat,
                    size: 28.0,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 20.0),
                  child: Text(
                    "$likeCount likes",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 20.0),
                  child: Text(
                    "${user.username} ",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Text(description))
              ],
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = likes[userId] == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter()
      ],
    );
  }

  showComments(BuildContext context,
      {String ownerId, String postId, String mediaUrl}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Comments(
                  postId: postId,
                  ownerId: ownerId,
                  mediaUrl: mediaUrl,
                )));
  }

  showProfile(context, {String profileId}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Profile(
                  profileId: profileId,
                )));
  }

  deletePost() async {
    //now Delete uploaded firebase object of post
    postsRef
        .document(ownerId)
        .collection("userPosts")
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    //now Delete uploaded image
    stoarageRef.child("post_$postId").delete();

    //delete from activity feed also
    await activityFeedRef
        .document(ownerId)
        .collection("feedItems")
        .where("postId", isEqualTo: postId)
        .getDocuments()
        .then((docs){
        docs.documents.forEach((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    });
    //finally delete all comments also GOD!!
    await commmentsRef
        .document(ownerId)
        .collection("comments")
        .getDocuments()
        .then((docs){
        docs.documents.forEach((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    });

  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (ctx) {
          return SimpleDialog(
            title: Text("Remove this post"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Remove", style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }
}
