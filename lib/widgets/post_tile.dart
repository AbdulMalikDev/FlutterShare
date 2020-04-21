import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttershare/pages/post_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/post.dart';

class PostTile extends StatelessWidget {
  Post post;
  PostTile(this.post);

  showPost(context)
  {
    Navigator.push(context, MaterialPageRoute(builder: (_)=>PostScreen(postId: post.postId,userId: post.ownerId,)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
