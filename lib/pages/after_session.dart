import 'package:app/pages/home_page.dart';
import 'package:app/pages/profile_page.dart';
import 'package:app/pages/calendar.dart';
import 'package:app/pages/therapy_page.dart';
import 'package:app/pages/therapy_page2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'noti_page.dart';
import 'dart:convert'; // To decode the API response

class AfterSession extends StatefulWidget {

  final String apiResponse; // 👈 add this

  AfterSession({required this.apiResponse}); // 👈 constructor

  @override
  State<AfterSession> createState() => _AfterSessionState();
}

class _AfterSessionState extends State<AfterSession> {
  // Controller for the feedback text input
  TextEditingController feedbackController = TextEditingController();
  String submittedFeedback = ""; // Variable to hold the submitted feedback
  String? summary; // Variable to hold the summary part of the API response

  // Function to parse the API response and extract the summary
  void parseApiResponse() {
    try {
      // Decode the API response string into a JSON map
      var responseMap = jsonDecode(widget.apiResponse);

      // Extract the 'summary' from the response
      setState(() {
        summary = responseMap['summary'];
      });
    } catch (e) {
      print('Error parsing API response: $e');
    }
  }

  // Function to submit feedback to Firestore
  void _submitFeedback() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && feedbackController.text.isNotEmpty) {
      // Get the current count of feedback entries for the user
      QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('feedback')
          .get();

      // Calculate the session number (based on the count of existing feedback)
      int sessionNumber = feedbackSnapshot.size + 1; // Adding 1 for the next session
      String sessionName = 'Session $sessionNumber';

      // Add the feedback document with the dynamic session name
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('feedback')
          .add({
        'session': sessionName, // Dynamic session name
        'feedback': feedbackController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        // Store the submitted feedback to display in the TextField
        submittedFeedback = feedbackController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback submitted successfully!')),
      );

      feedbackController.clear(); // Clear the input field after submission
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter feedback before submitting.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    parseApiResponse(); // Parse the API response when the page is loaded
  }

  @override
  Widget build(BuildContext context) {
    // Update the controller text dynamically based on feedback submission
    if (submittedFeedback.isNotEmpty) {
      feedbackController.text = submittedFeedback;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF078798),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_filled, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
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
      body: SingleChildScrollView( // Wrap the Column inside a SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Session Completion message
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF078798).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color(0xFF078798),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Session Completed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Lucida Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Feedback section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(7, 135, 152, 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color.fromRGBO(7, 135, 152, 1),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    // Display the summary from API response
                    summary != null
                        ? Text(
                      summary!,
                      style: TextStyle(fontSize: 16),
                    )
                        : CircularProgressIndicator(), // Show loading while parsing
                    Text(
                      'Feedback',
                      style: TextStyle(
                        color: Color(0xFF078798),
                        fontFamily: 'Inter',
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Write about your experience this session',
                      style: TextStyle(
                        color: Color(0xFF078798),
                        fontFamily: 'Inter',
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),

                    // Scrollable TextField for feedback input
                    TextField(
                      controller: feedbackController,
                      maxLines: null, // Allow unlimited lines of text
                      enabled: submittedFeedback.isEmpty, // Disable if feedback is submitted
                      decoration: InputDecoration(
                        hintText: 'Type here',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Color(0xFF078798),
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(10),
                      ),
                      style: TextStyle(
                        color: Color.fromRGBO(7, 135, 152, 1),
                        fontFamily: 'K2D',
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Submit Feedback Button
              Center(
                child: Container(
                  width: 250,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF078798),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton(
                    onPressed: _submitFeedback,
                    child: Text(
                      'Submit Feedback',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Other action buttons
              Center(
                child: Container(
                  width: 250,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF078798),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TherapyPage2()),
                      );
                    },
                    child: Text(
                      'Take another session',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),

              Center(
                child: Container(
                  width: 250,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF078798),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CalendarPage()),
                      );
                    },
                    child: Text(
                      'Book offline session',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



///full response
// import 'package:app/pages/home_page.dart';
// import 'package:app/pages/profile_page.dart';
// import 'package:app/pages/calendar.dart';
// import 'package:app/pages/therapy_page.dart';
// import 'package:app/pages/therapy_page2.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import 'noti_page.dart';
//
// class AfterSession extends StatefulWidget {
//
//   final String apiResponse; // 👈 add this
//
//   AfterSession({required this.apiResponse}); // 👈 constructor
//   @override
//   State<AfterSession> createState() => _AfterSessionState();
// }
//
// class _AfterSessionState extends State<AfterSession> {
//   // Controller for the feedback text input
//   TextEditingController feedbackController = TextEditingController();
//   String submittedFeedback = ""; // Variable to hold the submitted feedback
//
//   // Function to submit feedback to Firestore
//   void _submitFeedback() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user != null && feedbackController.text.isNotEmpty) {
//       // Get the current count of feedback entries for the user
//       QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('feedback')
//           .get();
//
//       // Calculate the session number (based on the count of existing feedback)
//       int sessionNumber = feedbackSnapshot.size + 1; // Adding 1 for the next session
//       String sessionName = 'Session $sessionNumber';
//
//       // Add the feedback document with the dynamic session name
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('feedback')
//           .add({
//         'session': sessionName, // Dynamic session name
//         'feedback': feedbackController.text,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       setState(() {
//         // Store the submitted feedback to display in the TextField
//         submittedFeedback = feedbackController.text;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Feedback submitted successfully!')),
//       );
//
//       feedbackController.clear(); // Clear the input field after submission
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter feedback before submitting.')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Update the controller text dynamically based on feedback submission
//     if (submittedFeedback.isNotEmpty) {
//       feedbackController.text = submittedFeedback;
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xFF078798),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.home_filled, color: Colors.white),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => HomePage()),
//             );
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => NotificationPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView( // Wrap the Column inside a SingleChildScrollView
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               // Session Completion message
//               Container(
//                 width: double.infinity,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Color(0xFF078798).withOpacity(0.7),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                     color: Color(0xFF078798),
//                     width: 2,
//                   ),
//                 ),
//                 child: Center(
//                   child: Text(
//                     'Session Completed',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontFamily: 'Lucida Sans',
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       height: 1,
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Feedback section
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Color.fromRGBO(7, 135, 152, 0.1),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                     color: Color.fromRGBO(7, 135, 152, 1),
//                     width: 2,
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(height: 10),
//                     Text(
//                       widget.apiResponse, // 👈 displaying API response here
//                       style: TextStyle(fontSize: 16),
//                     ),
//                     Text(
//                       'Feedback',
//                       style: TextStyle(
//                         color: Color(0xFF078798),
//                         fontFamily: 'Inter',
//                         fontSize: 25,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       'Write about your experience this session',
//                       style: TextStyle(
//                         color: Color(0xFF078798),
//                         fontFamily: 'Inter',
//                         fontSize: 16,
//                       ),
//                     ),
//                     SizedBox(height: 10),
//
//                     // Scrollable TextField for feedback input
//                     TextField(
//                       controller: feedbackController,
//                       maxLines: null, // Allow unlimited lines of text
//                       enabled: submittedFeedback.isEmpty, // Disable if feedback is submitted
//                       decoration: InputDecoration(
//                         hintText: 'Type here',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                           borderSide: BorderSide(
//                             color: Color(0xFF078798),
//                             width: 2,
//                           ),
//                         ),
//                         contentPadding: EdgeInsets.all(10),
//                       ),
//                       style: TextStyle(
//                         color: Color.fromRGBO(7, 135, 152, 1),
//                         fontFamily: 'K2D',
//                         fontSize: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 20),
//
//               // Submit Feedback Button
//               Center(
//                 child: Container(
//                   width: 250,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Color(0xFF078798),
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: TextButton(
//                     onPressed: _submitFeedback,
//                     child: Text(
//                       'Submit Feedback',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontFamily: 'Inter',
//                         fontSize: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               // Other action buttons
//               Center(
//                 child: Container(
//                   width: 250,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Color(0xFF078798),
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => TherapyPage2()),
//                       );
//                     },
//                     child: Text(
//                       'Take another session',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontFamily: 'Inter',
//                         fontSize: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               Center(
//                 child: Container(
//                   width: 250,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Color(0xFF078798),
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => CalendarPage()),
//                       );
//                     },
//                     child: Text(
//                       'Book offline session',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontFamily: 'Inter',
//                         fontSize: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




/// asadas
// import 'package:app/pages/home_page.dart';
// import 'package:app/pages/profile_page.dart';
// import 'package:app/pages/calendar.dart';
// import 'package:app/pages/therapy_page.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import 'noti_page.dart';
//
// class AfterSession extends StatefulWidget {
//   @override
//   State<AfterSession> createState() => _AfterSessionState();
// }
//
// class _AfterSessionState extends State<AfterSession> {
//   // Controller for the feedback text input
//   TextEditingController feedbackController = TextEditingController();
//
//   // Function to submit feedback to Firestore
//   // void _submitFeedback() async {
//   //   User? user = FirebaseAuth.instance.currentUser;
//   //   if (user != null && feedbackController.text.isNotEmpty) {
//   //     await FirebaseFirestore.instance
//   //         .collection('users')
//   //         .doc(user.uid)
//   //         .collection('feedback')
//   //         .add({
//   //       'session': 'Session 1', // Customize as needed
//   //       'feedback': feedbackController.text,
//   //       'timestamp': FieldValue.serverTimestamp(),
//   //     });
//   //
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Feedback submitted successfully!')),
//   //     );
//   //
//   //     feedbackController.clear(); // Clear the input field after submission
//   //   } else {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Please enter feedback before submitting.')),
//   //     );
//   //   }
//   // }
//   void _submitFeedback() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user != null && feedbackController.text.isNotEmpty) {
//       // Get the current count of feedback entries for the user
//       QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('feedback')
//           .get();
//
//       // Calculate the session number (based on the count of existing feedback)
//       int sessionNumber = feedbackSnapshot.size + 1; // Adding 1 for the next session
//       String sessionName = 'Session $sessionNumber';
//
//       // Add the feedback document with the dynamic session name
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('feedback')
//           .add({
//         'session': sessionName, // Dynamic session name
//         'feedback': feedbackController.text,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Feedback submitted successfully!')),
//       );
//
//       feedbackController.clear(); // Clear the input field after submission
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter feedback before submitting.')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xFF078798),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.home_filled, color: Colors.white),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => HomePage()),
//             );
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => NotificationPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             // Session Completion message
//             Container(
//               width: double.infinity,
//               height: 50,
//               decoration: BoxDecoration(
//                 color: Color(0xFF078798).withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(
//                   color: Color(0xFF078798),
//                   width: 2,
//                 ),
//               ),
//               // padding: EdgeInsets.all(16),
//               child: Center(
//                 child: Text(
//                   'Session Completed',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontFamily: 'Lucida Sans',
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     height: 1,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//
//             // Feedback section
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Color.fromRGBO(7, 135, 152, 0.1),
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(
//                   color: Color.fromRGBO(7, 135, 152, 1),
//                   width: 2,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Feedback',
//                     style: TextStyle(
//                       color: Color(0xFF078798),
//                       fontFamily: 'Inter',
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Write about your experience this session',
//                     style: TextStyle(
//                       color: Color(0xFF078798),
//                       fontFamily: 'Inter',
//                       fontSize: 16,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//
//                   TextField(
//                     controller: feedbackController,
//                     maxLines: 4,
//                     decoration: InputDecoration(
//                       hintText: 'Type here',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(
//                           color: Color(0xFF078798),
//                           width: 2,
//                         ),
//                       ),
//                       contentPadding: EdgeInsets.all(10),
//                     ),
//                     style: TextStyle(
//                       color: Color.fromRGBO(7, 135, 152, 1),
//                       fontFamily: 'K2D',
//                       fontSize: 18,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//
//             // Submit Feedback Button
//             Center(
//               child: Container(
//                 width: 250,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Color(0xFF078798),
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: TextButton(
//                   onPressed: _submitFeedback,
//                   child: Text(
//                     'Submit Feedback',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontFamily: 'Inter',
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 10),
//
//             // Other action buttons
//             Center(
//               child: Container(
//                 width: 250,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Color(0xFF078798),
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => TherapyPage()),
//                     );
//                   },
//                   child: Text(
//                     'Take another session',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontFamily: 'Inter',
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 10),
//
//             Center(
//               child: Container(
//                 width: 250,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: Color(0xFF078798),
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => CalendarPage()),
//                     );
//                   },
//                   child: Text(
//                     'Book offline session',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontFamily: 'Inter',
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//



/// fsads
// import 'package:app/pages/home_page.dart';
// import 'package:app/pages/profile_page.dart';
// import 'package:app/pages/calendar.dart';
// import 'package:app/pages/therapy_page.dart';
// import 'package:flutter/material.dart';
//
// import 'noti_page.dart';
//
// class AfterSession extends StatefulWidget {
//   @override
//   State<AfterSession> createState() => _AfterSessionState();
// }
//
// class _AfterSessionState extends State<AfterSession> {
//   // Controller for the feedback text input
//   TextEditingController feedbackController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xFF078798),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.home_filled, color: Colors.white),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => HomePage()),
//             );
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => NotificationPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),  // Add padding around the body content
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,  // Align the text to the left
//           children: <Widget>[
//             // Session Completion message in a box
//             Container(
//               width: double.infinity,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: Color(0xFF078798).withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(
//                   color: Color(0xFF078798),
//                   width: 2,
//                 ),
//               ),
//               padding: EdgeInsets.all(16),
//               child: Center(
//                 child: Text(
//                   'Session 1 Completed',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontFamily: 'Lucida Sans',
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     height: 1,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 20), // Space between sections
//
//             // Feedback section in a box
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Color.fromRGBO(7, 135, 152, 0.1), // Light blue background
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(
//                   color: Color.fromRGBO(7, 135, 152, 1), // Blue border color
//                   width: 2,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Feedback',
//                     style: TextStyle(
//                       color: Color(0xFF078798),
//                       fontFamily: 'Inter',
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Write about your experience this session',
//                     style: TextStyle(
//                       color: Color(0xFF078798),
//                       fontFamily: 'Inter',
//                       fontSize: 16,
//                     ),
//                   ),
//                   SizedBox(height: 10), // Space between description and feedback input
//
//                   TextField(
//                     controller: feedbackController,
//                     maxLines: 10,  // Allow multiple lines
//                     decoration: InputDecoration(
//                       hintText: 'Type here', // Placeholder text
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(
//                           color: Color(0xFF078798),
//                           width: 2,
//                         ),
//                       ),
//                       contentPadding: EdgeInsets.all(10),
//                     ),
//                     style: TextStyle(
//                       color: Color.fromRGBO(7, 135, 152, 1),
//                       fontFamily: 'K2D',
//                       fontSize: 18,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20), // Space between sections
//
//             // Action buttons (Take another session and Book offline session)
//             Container(
//               width: double.infinity,
//               height: 56,
//               decoration: BoxDecoration(
//                 color: Color(0xFF078798),
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               child: TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => TherapyPage()),
//                   );
//                 },
//                 child: Text(
//                   'Take another session',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontFamily: 'Inter',
//                     fontSize: 22,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16), // Space between the buttons
//             Container(
//               width: double.infinity,
//               height: 56,
//               decoration: BoxDecoration(
//                 color: Color(0xFF078798),
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               child: TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => CalendarPage()),
//                   );
//                 },
//                 child: Text(
//                   'Book offline session',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontFamily: 'Inter',
//                     fontSize: 22,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }