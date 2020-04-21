import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

Widget cachedNetworkImage(String mediaUrl) {
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    fit: BoxFit.cover,
    placeholder: (ctx, url) => Padding(
      padding: EdgeInsets.all(16),
      child: CircularProgressIndicator(),
    ),
    errorWidget: (ctx, _, __) => Icon(Icons.error),
  );
}
