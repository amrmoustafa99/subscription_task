import 'dart:io';

import 'package:video_player/video_player.dart';

Future<VideoPlayerController> openLocalVideo(String path) async {
  final controller = VideoPlayerController.file(File(path));
  await controller.initialize();
  return controller;
}
