import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';

class EditProfile extends StatefulWidget {
  final String userId;
  EditProfile({this.userId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final key = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  User user;
  TextEditingController nameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool nameIsValid = true;
  bool bioIsValid = true;

  getUser() async {
    DocumentSnapshot doc = await usersRef.document(widget.userId).get();
    user = User.fromDocument(doc);
    nameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      isLoading = true;
    });
    getUser();
  }

  buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              "Display Name",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
              hintText: "Update Display Name",
              errorText: nameIsValid ? null : "Please enter a valid Name"),
        )
      ],
    );
  }

  buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              "Bio",
              style: TextStyle(color: Colors.grey),
            )),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: bioIsValid ? null : "Please enter a valid bio ",
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.done,
              size: 30,
              color: Colors.green,
            ),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 8),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            CachedNetworkImageProvider(user.photoUrl),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: <Widget>[
                          buildDisplayNameField(),
                          buildBioField(),
                        ],
                      ),
                    ),
                    RaisedButton(
                      onPressed: () => validateInput(),
                      child: Text(
                        "Update Profile",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 20),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: FlatButton.icon(
                          onPressed: logout,
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          label: Text(
                            "Logout",
                            style: TextStyle(color: Colors.red, fontSize: 20),
                          )),
                    )
                  ],
                )
              ],
            ),
    );
  }

  validateInput() {
    setState(() {
      nameController.text.trim().length < 3 ||
              nameController.text.isEmpty
          ? nameIsValid = false
          : nameIsValid = true;
      bioController.text.trim().length > 100
          ? bioIsValid = false
          : bioIsValid = true;
    });


    if (nameIsValid && bioIsValid) {
      usersRef.document(widget.userId).updateData({
        "displayName": nameController.text.trim(),
        "bio": bioController.text.trim(),
      });
       SnackBar snackBar = SnackBar(
      content: Text("Profile Successfully Updated!"),
    );
    key.currentState.showSnackBar(snackBar);
    }
   
  }

  logout() {
    googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (_)=> Home()));
  }
}
