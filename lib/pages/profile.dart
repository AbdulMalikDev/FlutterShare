import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isFollowing  = false;
  String postOrientation = "grid";
  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  getFollowers() async
  {
    QuerySnapshot doc = await followersRef.document(widget.profileId).collection("userFollowers").getDocuments();
    setState(() {
    followerCount = doc.documents.length;
    });

  }

  getFollowing() async
  {
    QuerySnapshot doc = await followingRef.document(widget.profileId).collection("userFollowers").getDocuments();
    setState(() {  
    followingCount = doc.documents.length;
    });
    
  }

  checkIfFollowing() async
  {
    DocumentSnapshot doc = await followersRef.document(widget.profileId).collection("userFollowers").document(currentUserId).get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count,
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(userId: currentUserId)));
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 230.0,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    // viewing your own profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    }else if(isFollowing)
    {
      return buildButton(text: "Unfollow", function: handleUnfollowuser);
    }else if(!isFollowing)
    {
      return buildButton(text: "Follow", function: handlefollowuser);
    }
  }

  handleUnfollowuser()
  {
     setState(() {
      isFollowing = false;
    });
    // remove follower
    followersRef.document(widget.profileId).collection("userFollowers").document(currentUserId).get().then((doc){if(doc.exists){doc.reference.delete();}});
    // remove profile from the list of profiles we are following
    followingRef.document(currentUserId).collection("userFollowing").document(widget.profileId).get().then((doc){if(doc.exists){doc.reference.delete();}});
    // delete from activityFeed Notifications
    activityFeedRef.document(widget.profileId).collection("feedItems").document(currentUserId).get().then((doc){if(doc.exists){doc.reference.delete();}});
    
    setState(() {
      followerCount--;
    });
  }

  handlefollowuser()
  {
    setState(() {
      isFollowing = true;
    });
    // add follower to the profile we followed
    followersRef.document(widget.profileId).collection("userFollowers").document(currentUserId).setData({});
    // add profile in the list of profiles we are following
    followingRef.document(currentUserId).collection("userFollowing").document(widget.profileId).setData({});
    // show in activityFeed Notifications
    activityFeedRef.document(widget.profileId).collection("feedItems").document(currentUserId).setData({
      "type":"follow",
      "ownerId":widget.profileId,
      "username":currentUser.username,
      "userId" : currentUserId,
      "userProfileImg" : currentUser.photoUrl,
      "timestamp" : DateTime.now(),
    });
    setState(() {
      followerCount++;
    });

  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom:12.0),
                    child: CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top:8.0),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildCountColumn("posts", postCount.toString()),
                              buildCountColumn("followers", followerCount.toString()),
                              buildCountColumn("following", followingCount.toString()),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildProfileButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.username??"",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    }else if(posts.isEmpty)
    {
        return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset("assets/images/no_content.svg", height: 260),
          Container(
            padding: EdgeInsets.only(top: 20),
            
              child: Text(
                "No Posts",
                style: TextStyle(fontSize: 40, color: Colors.redAccent,fontWeight: FontWeight.bold),
              ),
              
           
          )
        ],
      ),
    );
    }
    else if(postOrientation == 'grid'){

    List<GridTile> gridtiles = [];

    posts.forEach((post) {
      gridtiles.add(GridTile(
        child: PostTile(post),
      ));
    });

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 1.5,
      mainAxisSpacing: 1.5,
      childAspectRatio: 1.0,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: gridtiles,
    );
    }else if(postOrientation == 'linear')
    {

    return Column(
      children: posts,
    );
    }
  }

  buildPostOrientationTile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          onPressed: () 
          {
            setState(() {  
            postOrientation = 'grid';
            });
          },
          color: postOrientation == 'grid' ? Theme.of(context).primaryColor : Colors.grey,
        ),
        IconButton(
          icon: Icon(Icons.list),
          
          onPressed: () 
          {
            setState(() {
            postOrientation = 'linear';  
            });
          },
          color: postOrientation == 'grid'  ? Colors.grey : Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildPostOrientationTile(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
