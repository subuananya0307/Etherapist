import 'package:flutter/material.dart';
import 'package:app/pages/appointments_page.dart';
import 'package:app/pages/quiz_page.dart';
import 'edit_page.dart';
import 'mindEx_page.dart';
import 'noti_page.dart';
import 'profile_page.dart';
import 'therapy_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;
  String userEmail = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Widget> _pages = [
    QuizPage(),
    MindExPage(),
    ProfilePage(),
    TherapyPage(),
    EditPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      print("User ID: ${user.uid}");
      print("User Email: ${user.email}");

      setState(() {
        userEmail = user.email ?? 'No email available';
      });
    } else {
      print("No user logged in.");
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF078798),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'eTherapy',
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              userEmail,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF078798),
        unselectedItemColor: const Color(0xFF078798),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle),
            label: 'MindEx',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.healing),
            label: 'Therapy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Edit',
          ),
        ],
      ),
    );
  }
}
