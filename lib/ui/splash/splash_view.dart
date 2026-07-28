import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants.dart';
import '../chat/chat_view.dart';

/// Plays one of the 7 splash videos in rotation, then hands off to ChatView.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  VideoPlayerController? _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initSplash();
    // Must run before any ad is requested (first request happens in
    // ChatView, never here) — iOS 14.5+ rejects apps that request the
    // IDFA-backed ad SDK without first showing this prompt.
    _requestTrackingAuthorization();
  }

  Future<void> _requestTrackingAuthorization() async {
    // dart:io Platform.* throws UnsupportedError on web — check kIsWeb first.
    if (kIsWeb || !Platform.isIOS) return;
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  Future<void> _initSplash() async {
    final Box settingsBox = Hive.box(HiveBoxes.settings);

    final int index = settingsBox.get(
      AppConstants.lastPlayedIndexKey,
      defaultValue: 1,
    ) as int;

    final int nextIndex = (index % AppConstants.splashVideoCount) + 1;
    await settingsBox.put(AppConstants.lastPlayedIndexKey, nextIndex);

    final controller = VideoPlayerController.asset(
      'assets/videos/splash$index.mp4',
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    controller.setLooping(false);
    controller.addListener(_onVideoTick);

    setState(() => _controller = controller);
    controller.play();
  }

  void _onVideoTick() {
    if (_navigated) return;
    final VideoPlayerController? controller = _controller;
    if (controller == null) return;
    final VideoPlayerValue value = controller.value;

    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration) {
      _navigated = true;
      // Detach before navigating: the controller must not fire further
      // ticks (or receive further disposal) once the route transition
      // starts unmounting this widget.
      controller.removeListener(_onVideoTick);
      _goToChat();
    }
  }

  void _goToChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatView()),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;
    final bool ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: ready
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
