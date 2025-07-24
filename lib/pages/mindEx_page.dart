import 'package:flutter/material.dart';
import 'package:app/pages/video_page.dart';

class MindExPage extends StatefulWidget {
  @override
  State<MindExPage> createState() => _MindExPageState();
} 

class _MindExPageState extends State<MindExPage> {
  final List<Map<String, String>> exercises = [
    {'name': 'Meditation', 'image': 'lib/images/Image.png', 'videoId': 'uqGTphrGHi4'},
    {'name': 'Visualization', 'image': 'lib/images/Image (1).png', 'videoId': 't1rRo6cgM_E'},
    {'name': 'Yoga', 'image': 'lib/images/Image (3).png', 'videoId': 'Ycyz2C0bNUg'},
    {'name': 'Slow Breaths', 'image': 'lib/images/Image (4).png', 'videoId': '8vkYJf8DOsc'},
    {'name': 'Moderate Exercise', 'image': 'lib/images/Image (5).png', 'videoId': 't3uK039WdaM'},
    {'name': 'Muscle Relaxation', 'image': 'lib/images/Image (2).png', 'videoId': 'ihO02wUzgkc'},
  ];

  // Navigate to the YouTube Player page with the correct video ID
  void _openExerciseVideo(BuildContext context, String videoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubePlayerPage(videoId: videoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Title Section
              const Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Mind Exercises',
                  style: TextStyle(
                    color: Color(0xFF06013F ),
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Simple exercises to ease your anxiety.',
                  style: TextStyle(
                    color: Color.fromRGBO(0, 0, 0, 1),
                    fontFamily: 'Tuffy',
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images Section (Grid View)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1,
                  ),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Open YouTube video for the selected exercise
                        _openExerciseVideo(
                          context,
                          exercises[index]['videoId']!,
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Image Section
                          Container(
                            width: double.infinity,
                            height: 125,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromRGBO(6, 1, 62, 1),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(27),
                              image: DecorationImage(
                                image: AssetImage(exercises[index]['image']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Exercise Name (Caption)
                          Text(
                            exercises[index]['name']!,
                            style: const TextStyle(
                              color: Color.fromRGBO(6, 1, 63, 1),
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
