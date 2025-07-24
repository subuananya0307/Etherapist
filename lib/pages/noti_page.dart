import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatefulWidget {
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchTodaysAppointments();
  }

  void fetchTodaysAppointments() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    // Get today's date in "YYYY-MM-DD" format
    DateTime now = DateTime.now();
    String todayString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    _firestore
        .collection('users')
        .doc(userId)
        .collection('appointments')
        .where('date', isEqualTo: todayString) // ✅ Filter only today's
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> newNotifications = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String timeString = data['time'] ?? 'Unknown Time';

        newNotifications.add({
          'time': timeString,
          'title': "Appointment Today",
          'description': data['description'] ?? 'Scheduled appointment',
          'icon': Icons.calendar_today,
        });
      }

      setState(() {
        notifications = newNotifications;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontSize: 20, color: Colors.white)),
        backgroundColor: const Color(0xFF078798),
      ),
      body: notifications.isEmpty
          ? const SizedBox() // ✅ Shows nothing if no appointments
          : ListView(
        padding: EdgeInsets.zero,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20.0, right: 10.0, top: 10.0, bottom: 10.0),
            child: Center(
              child: Text(
                'Today’s Appointments',
                style: TextStyle(
                  color: Color(0xFF078798),
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          for (var notification in notifications)
            NotificationCard(
              time: notification['time'],
              title: notification['title'],
              description: notification['description'],
              icon: notification['icon'],
            ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String time;
  final String title;
  final String description;
  final IconData icon;

  const NotificationCard({
    required this.time,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, left: 10.0, right: 10.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          child: Row(
            children: [
              Icon(icon, size: 28, color: const Color(0xFF078798)),

              const SizedBox(width: 15),

              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                time,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
//
// class NotificationPage extends StatefulWidget {
//   @override
//   State<NotificationPage> createState() => _NotificationPageState();
// }
//
// class _NotificationPageState extends State<NotificationPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications', style: TextStyle(fontSize: 20, color: Colors.white)),
//         backgroundColor: const Color(0xFF078798),
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: ListView(
//                 padding: EdgeInsets.zero,
//                 children: [
//                   const Padding(
//                     padding: EdgeInsets.only(left: 20.0, right: 10.0, top: 10.0, bottom: 10.0),
//                     child: Center(
//                       child: Text(
//                         'Today',
//                         style: TextStyle(
//                           color: Color(0xFF078798),
//                           fontFamily: 'ADLaM Display',
//                           fontSize: 23,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   NotificationCard(time: '12:00 PM', title: 'Update', description: 'Session Summary updated', icon: Icons.update),
//                   // NotificationCard(time: '9:56 AM', title: 'Check-In', description: 'It\'s been a while! How are you feeling?', icon: Icons.sentiment_satisfied),
//                   NotificationCard(time: '9:56 AM', title: 'Appointment', description: 'Appointment at 10:30 PM today', icon: Icons.calendar_today),
//                   const Padding(
//                     padding: EdgeInsets.only(left: 20.0, right: 10.0, top: 15.0, bottom: 10.0),
//                     child: Center(
//                       child: Text(
//                         'Yesterday',
//                         style: TextStyle(
//                           color: Color(0xFF078798),
//                           fontFamily: 'ADLaM Display',
//                           fontSize: 23,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   NotificationCard(time: '10:53 AM', title: 'Successful rescheduling', description: 'Your appointment on 28/02/25 is success', icon: Icons.schedule),
//                   // NotificationCard(time: '9:56 AM', title: 'Appointment', description: 'Doctor rescheduled appointment on 26/09..', icon: Icons.calendar_today),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class NotificationCard extends StatelessWidget {
//   final String time;
//   final String title;
//   final String description;
//   final IconData icon;
//
//   NotificationCard({
//     required this.time,
//     required this.title,
//     required this.description,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 5.0, left: 10.0, right: 10.0),
//       child: Card(
//         elevation: 6, // Increased elevation for a more prominent shadow
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16), // Rounded corners
//         ),
//         color: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
//           child: Row(
//             children: [
//               // Colorful Icon to make the notification more engaging
//               Icon(icon, size: 28, color: const Color(0xFF078798)),
//
//               const SizedBox(width: 15), // Adjusted space between icon and text column
//
//               // Column for Title and Description
//               Flexible(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         color: Color.fromRGBO(9, 10, 10, 1),
//                         fontFamily: 'ADLaM Display',
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                     ),
//                     Text(
//                       description,
//                       style: const TextStyle(
//                         color: Color.fromRGBO(119, 119, 119, 1),
//                         fontFamily: 'Actor',
//                         fontSize: 14,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 2,
//                     ),
//                   ],
//                 ),
//               ),
//
//               const Spacer(),
//
//               // Time Text with a muted tone
//               Text(
//                 time,
//                 style: const TextStyle(
//                   color: Color.fromRGBO(134, 134, 134, 1),
//                   fontFamily: 'SF Pro Display',
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

