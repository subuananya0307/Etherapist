import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../util/my_button.dart';
import 'login_page.dart';
import 'register_page.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({Key? key}) : super(key: key);

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  PageController _controller = PageController();
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // PageView section (larger portion)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Stack(
                    children: [
                      PageView(
                        controller: _controller,
                        onPageChanged: (index) {
                          setState(() {
                            onLastPage = (index == 2);
                          });
                        },
                        children: [
                          buildOnboardingPage(
                            image: 'lib/images/img.png',
                            title: 'Welcome to eTherapist!',
                            description: 'Embrace Life, Overcome Anxiety',
                          ),
                          buildFeaturePage(
                            image: 'lib/images/pg2.png',
                            title: 'For Patients',
                            features: [
                              FeatureItem(
                                icon: Icons.favorite,
                                title: 'Personalized Therapy',
                                description:
                                'Tailored treatment based on your unique anxiety triggers.',
                              ),
                              FeatureItem(
                                icon: Icons.vrpano,
                                title: 'Immersive VR Scenarios',
                                description:
                                'Practice social settings safely from home.',
                              ),
                              FeatureItem(
                                icon: Icons.lock,
                                title: 'Private & Self-Paced',
                                description:
                                'Progress without judgment, at your own pace.',
                              ),
                              FeatureItem(
                                icon: Icons.bar_chart,
                                title: 'Real-Time Feedback',
                                description:
                                'Track improvements with continuous insights.',
                              ),
                            ],
                          ),
                          buildFeaturePage(
                            image: 'lib/images/pg3.png',
                            title: 'For Doctors',
                            features: [
                              FeatureItem(
                                icon: Icons.control_camera,
                                title: 'Adaptive Treatment Plans',
                                description:
                                'Receive tailored therapy recommendations.',
                              ),
                              FeatureItem(
                                icon: Icons.monitor_heart,
                                title: 'Remote Monitoring',
                                description:
                                'Track progress and adjust treatments in real-time.',
                              ),
                              FeatureItem(
                                icon: Icons.analytics,
                                title: 'Comprehensive Health Insights',
                                description:
                                'Ensure better results with evidence-based therapy, evaluated alongside patients',
                              ),
                            ],
                          ),
                        ],
                      ),

                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Row(
                            mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                  onTap: (){
                                    _controller.previousPage(
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.easeIn,
                                    );},
                                  child: Text(' < ')
                              ),
                              SmoothPageIndicator(
                                controller: _controller,
                                count: 3,
                                effect: const ExpandingDotsEffect(
                                  activeDotColor: Colors.blue,
                                  dotHeight: 8,
                                  dotWidth: 8,
                                ),
                              ),
                              GestureDetector(
                                  onTap: (){
                                    _controller.nextPage(
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.easeIn,
                                    );},
                                  child: Text(' > ')
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons section (smaller portion)
              SizedBox(height: 20),
              MyButton(
                text: "Log In",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
              ),
              SizedBox(height: 10),
              MyButton(
                text: "Sign Up",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Register()),
                  );
                },
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOnboardingPage({
    required String image,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 200),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildFeaturePage({
    required String image,
    required String title,
    required List<FeatureItem> features,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(image, height: 200),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          ...features.map(
                (feature) => ListTile(
              leading: Icon(feature.icon, color: Colors.blue),
              title: Text(
                feature.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                feature.description,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
