import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pod_player/pod_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../providers/my_courses.dart';

class PlayVideoFromYoutube extends StatefulWidget {
  // static const routeName = '/fromVimeoId';
  final int courseId;
  final int? lessonId;
  final String videoUrl;
  const PlayVideoFromYoutube(
      {super.key,
      required this.courseId,
      this.lessonId,
      required this.videoUrl});

  @override
  State<PlayVideoFromYoutube> createState() => _PlayVideoFromVimeoIdState();
}

class _PlayVideoFromVimeoIdState extends State<PlayVideoFromYoutube> {
  late final PodPlayerController controller;
  final videoTextFieldCtr = TextEditingController();

  Timer? timer;

  @override
  void initState() {
    controller = PodPlayerController(
      playVideoFrom: PlayVideoFrom.youtube(widget.videoUrl),
    )..initialise();
    super.initState();

    if (widget.lessonId != null) {
      timer = Timer.periodic(
          const Duration(seconds: 5), (Timer t) => updateWatchHistory());
    }
  }

  Future<void> updateWatchHistory() async {
    if (controller.isVideoPlaying) {
      final prefs = await SharedPreferences.getInstance();
      final token = (prefs.getString('access_token') ?? '');
      dynamic url;
      if (token.isNotEmpty) {
        url = "$baseUrl/api/update_watch_history/$token";
        // print(url);
        // print(controller.currentVideoPosition.inSeconds);
        try {
          final response = await http.post(
            Uri.parse(url),
            body: {
              'course_id': widget.courseId.toString(),
              'lesson_id': widget.lessonId.toString(),
              'current_duration':
                  controller.currentVideoPosition.inSeconds.toString(),
            },
          );

          final responseData = json.decode(response.body);
          // print(responseData);
          if (responseData == null) {
            return;
          } else {
            var isCompleted = responseData['is_completed'];
            if (isCompleted == 1) {
              // ignore: use_build_context_synchronously
              Provider.of<MyCourses>(context, listen: false)
                  .updateDripContendLesson(
                      widget.courseId,
                      responseData['course_progress'],
                      responseData['number_of_completed_lessons']);
            }
          }
        } catch (error) {
          // print(error.toString());
          rethrow;
        }
      } else {
        return;
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    if (widget.lessonId != null) {
      timer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kBackgroundColor,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: PodVideoPlayer(
            controller: controller,
          ),
        ),
      ),
    );
  }
}
