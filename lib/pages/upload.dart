import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload> {
  File file;
  bool isLoading = false;
  String postId = Uuid().v4();
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  handlePhotoFromCamera() async {
    Navigator.pop(context);
    File image = await ImagePicker.pickImage(
        source: ImageSource.camera, maxHeight: 675, maxWidth: 900);
    setState(() {
      file = image;
    });
  }

  handlePhotoFromGallery() async {
    Navigator.pop(context);
    File image = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxHeight: 675, maxWidth: 900);
    setState(() {
      file = image;
    });
  }

  selectImage(BuildContext contextq) {
    showDialog(
        context: contextq,
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: SimpleDialog(
              title: Text("Create a Post"),
              children: <Widget>[
                SizedBox(
                  height: 20,
                ),
                SimpleDialogOption(
                  child: Text(
                    "Photo with Camera ",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: handlePhotoFromCamera,
                ),
                SizedBox(
                  height: 20,
                ),
                SimpleDialogOption(
                  child: Text(
                    "Image From Gallery ",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: handlePhotoFromGallery,
                ),
                SizedBox(
                  height: 20,
                ),
                SimpleDialogOption(
                  child: Text(
                    "Cancel ",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        });
  }

  buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset("assets/images/upload.svg", height: 260),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: RaisedButton(
              onPressed: () => selectImage(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Upload",
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
              color: Colors.deepOrange,
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImage = File("$path/img_$postId.jpg")
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImage;
    });
  }

  Future<String> uploadImage() async {
    StorageUploadTask uploadTask =
        stoarageRef.child("post_$postId.jpg").putFile(file);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFireStore(String mediaUrl, String location, String description) {
    postId = Uuid().v4();
    postsRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
    captionController.clear();
    locationController.clear();
    setState(() {
      file=null;
      isLoading =false;
      
    });
  }

  handleSubmit() async {
    print("Handle Submit");
    setState(() {
      isLoading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage();
    createPostInFireStore(
        mediaUrl, locationController.text , captionController.text);
  }

  buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: clearImage,
        ),
        title: Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(
              "POST",
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            onPressed: isLoading ? null : () => handleSubmit(),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isLoading ? LinearProgressIndicator() : Text(""),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Center(
              // child: AspectRatio(
              //   aspectRatio: 11 / 9,
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: FileImage(file), fit: BoxFit.contain)),
              ),
              // ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                    hintText: "Enter Your Caption..", border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop, size: 35),
            title: TextField(
              controller: locationController,
              decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none),
            ),
          ),
          Container(
            height: 100,
            width: 200,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              color: Colors.blueAccent,
              textColor: Colors.white,
              onPressed: () => handleCurrentLocation(),
              icon: Icon(Icons.my_location),
              label: Text("Use My Current Location"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  handleCurrentLocation() async
  {
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high,);
    List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String formattedAddress = '${placemark.locality} , ${placemark.country}';
    locationController.text = formattedAddress;
  }
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
