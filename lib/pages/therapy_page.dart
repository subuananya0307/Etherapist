import 'package:app/pages/calendar.dart';
import 'package:app/pages/profile_page.dart';
import 'package:app/pages/quiz_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'consent.dart';
import 'consent2.dart';
import 'edit_page.dart';
import 'mindEx_page.dart';

class TherapyPage extends StatefulWidget {
  @override
  State<TherapyPage> createState() => _TherapyPage();
}

class _TherapyPage extends State<TherapyPage> {
  String userEmail = "Loading...";
  int _selectedIndex = 0;  // Add the selected index variable to track which page is active.

  final List<Widget> _pages = [
    QuizPage(),
    MindExPage(),
    ProfilePage(),
    TherapyPage(),
    EditPage(),
  ];
  Future<void> _fetchUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? "No Email";
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Choose Therapy Mode',
                style: TextStyle(
                  color: Color(0xFF06013F),
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF078798).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all( color: Color(0xFF078798),width: 2,),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.video_call, size: 40,color: Color(0xFF06013F),),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'VIRTUAL THERAPY SESSIONS',
                            style: TextStyle(
                              color: Color(0xFF06013F),
                              fontFamily: 'K2D',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // One-to-One Conversation Section
              TherapyOptionCard(
                title: 'One-to-One Conversation',
                description: 'Practice personal interactions to ease social discomfort.',
                icon: Icons.arrow_circle_right_rounded,
                onTap:() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => consentPage()),
                  );
                },

              ),
              SizedBox(height: 20),
              // Exam Anxiety Scenario Section
              // TherapyOptionCard(
              //   title: 'Exam Anxiety Scenario',
              //   description: 'Simulate test conditions to reduce stress and improve focus.',
              //   icon: Icons.arrow_circle_right_rounded,
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => consentPage()),
              //     );
              //   },
              // ),
              // SizedBox(height: 20),
              // Public Speaking Section
              TherapyOptionCard(
                title: 'Public Speaking',
                description: 'Face a virtual audience to overcome fear and boost confidence.',
                icon: Icons.arrow_circle_right_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => consentPage2()
                    ),
                  );
                },
              ),
              SizedBox(height: 20),


              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF078798).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF078798), width: 2),
                ),
                child: Column(
                  children: <Widget>[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.phone, size: 40,color: Color(0xFF06013F),),
                        SizedBox(width: 15),
                        Text(
                          'OFFLINE SESSIONS',
                          style: TextStyle(
                            color: Color(0xFF06013F),
                            fontFamily: 'K2D',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CalendarPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFF078798),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Book Offline Session',
                        style: TextStyle(fontFamily: 'K2D', fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class TherapyOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const TherapyOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 25.0,),
        child: Container(
          child: Row(
            children: <Widget>[
              Icon(icon, size: 36, color: Color.fromRGBO(7, 135, 152, 1)),
              SizedBox(width: 10),
              Expanded(  // Ensures the Column can take the remaining space and allow wrapping
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: Color.fromRGBO(7, 135, 152, 1),
                        fontFamily: 'K2D',
                        fontSize: 18,
                      ),
                      softWrap: true,  // Ensures the text wraps to the next line
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.55),
                        fontFamily: 'K2D',
                        fontSize: 16,
                      ),
                      softWrap: true,  // Ensures the text wraps to the next line
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
