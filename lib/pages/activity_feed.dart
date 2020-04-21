import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .document(currentUser.id)
        .collection("feedItems")
        .orderBy("timestamp", descending: true)
        .limit(50)
        .getDocuments();
    snapshot.documents.forEach((doc) {
      print("every documents");
    });

    return snapshot.documents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Activity Feed"),
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            List<ActivityFeedItem> activityFeedItems = [];
            snapshot.data.forEach((doc) {
              activityFeedItems.add(ActivityFeedItem.from(doc));
            });
            return ListView.builder(
                itemCount: activityFeedItems.length,
                itemBuilder: (ctx, index) => activityFeedItems[index]);
          },
        ),
      ),
    );
  }
}

Widget mediaPreview;
String feedText;

class ActivityFeedItem extends StatelessWidget {
  String username;
  String comment;
  Timestamp timestamp;
  String avatarUrl; //
  String mediaUrl; //
  String userId; //
  String type;
  String postId;

  ActivityFeedItem(this.username, this.comment, this.timestamp, this.avatarUrl,
      this.userId, this.mediaUrl, this.type,this.postId);

  factory ActivityFeedItem.from(doc) {
    return ActivityFeedItem(
      doc["username"],
      doc["comment"],
      doc["timestamp"],
      doc["userProfileImg"],
      doc["userId"],
      doc["mediaUrl"],
      doc["type"],
      doc["postId"],
    );
  }

  showPost(context)
  {
    Navigator.push(context, MaterialPageRoute(builder: (_)=>PostScreen(postId: postId,userId: userId,)));
  }

  configureMediaPreview(BuildContext context) {
    if (type == "like" || type == "comment") {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: CachedNetworkImageProvider(mediaUrl),
                      fit: BoxFit.cover)),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text("");
    }

    if (type == 'like') {
      feedText = " liked your post";
    } else if (type == 'follow') {
      feedText = ' is following you';
    } else if (type == 'comment') {
      feedText = ' replied: $comment';
    } else {
      feedText = " Error: type $type";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey,
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          title: GestureDetector(
            onTap: () => showProfile(context,profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(text: username,style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "$feedText"),

                ]
              ),
              
            ),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
          trailing: mediaPreview,
        ),
      ),
    );
  }

  showProfile(context, {String profileId})
  {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Profile(profileId: profileId,)));
  }
}
