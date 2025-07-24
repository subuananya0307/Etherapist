// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class NotificationPage2 extends StatefulWidget {
//   @override
//   State<NotificationPage2> createState() => _NotificationPageState2();
// }
//
// class _NotificationPageState2 extends State<NotificationPage2> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> notifications = [];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchAppointments(); // Fetch appointments on page load
//   }
//
//   void fetchAppointments() async {
//     String userId = FirebaseAuth.instance.currentUser!.uid; // Get logged-in user ID
//
//     _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('appointments')
//         .snapshots()
//         .listen((snapshot) {
//       List<Map<String, dynamic>> newNotifications = [];
//
//       for (var doc in snapshot.docs) {
//         var data = doc.data();
//         DateTime appointmentDate = (data['date'] as Timestamp).toDate();
//         String formattedTime =
//             "${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')} ${appointmentDate.hour >= 12 ? 'PM' : 'AM'}";
//
//         String title = appointmentDate.day == DateTime.now().day
//             ? "Appointment Today"
//             : "Successfully Scheduled an Appointment";
//
//         newNotifications.add({
//           'time': formattedTime,
//           'title': title,
//           'description': data['description'] ?? 'Appointment scheduled',
//           'icon': Icons.calendar_today,
//         });
//       }
//
//       setState(() {
//         notifications = newNotifications;
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications',
//             style: TextStyle(fontSize: 20, color: Colors.white)),
//         backgroundColor: const Color(0xFF078798),
//       ),
//       body: notifications.isEmpty
//           ? const Center(child: Text("No notifications yet"))
//           : ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(left: 20.0, right: 10.0, top: 10.0, bottom: 10.0),
//             child: Center(
//               child: Text(
//                 'Recent Appointments',
//                 style: TextStyle(
//                   color: Color(0xFF078798),
//                   fontFamily: 'ADLaM Display',
//                   fontSize: 23,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           for (var notification in notifications)
//             NotificationCard(
//               time: notification['time'],
//               title: notification['title'],
//               description: notification['description'],
//               icon: notification['icon'],
//             ),
//         ],
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
//   const NotificationCard({
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
//               Icon(icon, size: 28, color: const Color(0xFF078798)), // Icon color
//
//               const SizedBox(width: 15), // Adjusted space between icon and text column
//
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
//







import 'package:flutter/material.dart';

class NotificationPage2 extends StatefulWidget {
  @override
  State<NotificationPage2> createState() => _NotificationPageState2();
}

class _NotificationPageState2 extends State<NotificationPage2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontSize: 20, color: Colors.white)),
        backgroundColor: const Color(0xFF078798),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0, right: 10.0, top: 10.0, bottom: 10.0),
                    child: Center(
                      child: Text(
                        'Today',
                        style: TextStyle(
                          color: Color(0xFF078798),
                          fontFamily: 'ADLaM Display',
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  NotificationCard(time: '9:56 AM', title: 'Appointment', description: 'Appointment at 10:30 PM today', icon: Icons.calendar_today),
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0, right: 10.0, top: 15.0, bottom: 10.0),
                    child: Center(
                      child: Text(
                        'Yesterday',
                        style: TextStyle(
                          color: Color(0xFF078798),
                          fontFamily: 'ADLaM Display',
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  NotificationCard(time: '10.53 AM', title: 'Successful rescheduling', description: 'An appointment is scheduled on 28/02/25', icon: Icons.schedule),
                  // NotificationCard(time: '9:56 AM', title: 'Appointment', description: 'Doctor rescheduled appointment on 26/09..', icon: Icons.calendar_today),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String time;
  final String title;
  final String description;
  final IconData icon;

  NotificationCard({
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
        elevation: 6, // Increased elevation for a more prominent shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          child: Row(
            children: [
              // Colorful Icon to make the notification more engaging
              Icon(icon, size: 28, color: const Color(0xFF078798)),

              const SizedBox(width: 15), // Adjusted space between icon and text column

              // Column for Title and Description
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color.fromRGBO(9, 10, 10, 1),
                        fontFamily: 'ADLaM Display',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color.fromRGBO(119, 119, 119, 1),
                        fontFamily: 'Actor',
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Time Text with a muted tone
              Text(
                time,
                style: const TextStyle(
                  color: Color.fromRGBO(134, 134, 134, 1),
                  fontFamily: 'SF Pro Display',
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

