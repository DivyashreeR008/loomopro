
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HelpAndLearningScreen extends StatelessWidget {
  const HelpAndLearningScreen({super.key});

  // Replace with your actual video URLs
  static const List<Map<String, String>> _videoData = [
    {
      'title': 'How to Create Your Profile',
      'url': 'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4',
    },
    {
      'title': 'How to Add a New Product',
      'url': 'https://assets.mixkit.co/videos/preview/mixkit-daytime-city-traffic-aerial-view-56-large.mp4',
    },
    {
      'title': 'Tips for Taking Great Product Photos',
      'url': 'https://assets.mixkit.co/videos/preview/mixkit-a-girl-blowing-a-bubble-gum-at-an-amusement-park-1226-large.mp4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Learning'),
      ),
      body: ListView.builder(
        itemCount: _videoData.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _videoData[index]['title']!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                VideoPlayerWidget(videoUrl: _videoData[index]['url']!),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {}); // Ensure the first frame is shown
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                Center(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
  }
}
