import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class Appointment {
  final DateTime date;
  final String time;

  Appointment({required this.date, required this.time});
}

class AppPage extends StatefulWidget {
  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  DateTime _focusedDate = DateTime.now();
  Map<DateTime, List<Appointment>> appointments = {};
  Map<DateTime, List<Appointment>> availableAppointments = {};

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _fetchAvailableSlots();
  }

  Future<void> _fetchAvailableSlots() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists || !(userDoc.data() as Map<String, dynamic>).containsKey('assignedDoctorId')) {
      return;
    }

    String assignedDoctorId = userDoc['assignedDoctorId'];
    print("Doctor ID: $assignedDoctorId");

    QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(assignedDoctorId)
        .collection('slots')
        .get();

    if (slotSnapshot.docs.isEmpty) {
      print("No slots found for doctor: $assignedDoctorId");
    }

    Map<DateTime, List<Appointment>> tempAppointments = {};

    for (var doc in slotSnapshot.docs) {
      if (doc.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('date') && data.containsKey('time')) {
          String dateString = data['date'];
          String time = data['time'];

          try {
            // Parse date correctly, making sure month and day are two digits
            List<String> dateParts = dateString.split('-');
            DateTime date = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1].padLeft(2, '0')),  // Ensure month has two digits
              int.parse(dateParts[2].padLeft(2, '0')),  // Ensure day has two digits
            );

            // Normalize the date to remove the time component
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);

            if (!tempAppointments.containsKey(normalizedDate)) {
              tempAppointments[normalizedDate] = [];
            }
            tempAppointments[normalizedDate]!.add(
              Appointment(
                time: time,
                date: date,
              ),
            );
          } catch (e) {
            print("Error parsing date: $dateString - $e");
          }
        } else {
          print("Invalid slot document: $doc");
        }
      }
    }

    setState(() {
      availableAppointments = tempAppointments;
    });
  }

  Future<void> _fetchAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .get();

      Map<DateTime, List<Appointment>> loadedAppointments = {};
      for (var doc in snapshot.docs) {
        try {
          // Parse date and normalize it to midnight
          String dateString = doc['date'];
          List<String> dateParts = dateString.split('-');
          DateTime date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1].padLeft(2, '0')),  // Ensure month has two digits
            int.parse(dateParts[2].padLeft(2, '0')),  // Ensure day has two digits
          );
          DateTime normalizedDate = DateTime(date.year, date.month, date.day);

          // Extract time
          String time = doc['time'];

          // Create appointment object
          Appointment appointment = Appointment(
            date: normalizedDate,
            time: time,
          );

          // Store in map
          loadedAppointments.putIfAbsent(normalizedDate, () => []).add(appointment);
        } catch (e) {
          print("Error parsing appointment: ${doc.data()}, Error: $e");
        }
      }

      setState(() {
        appointments = loadedAppointments;
      });
    }
  }

  List<Appointment> _getUpcomingAppointments() {
    DateTime currentDate = DateTime.now();

    return appointments.entries
        .where((entry) => entry.key.isAfter(currentDate) || isSameDay(entry.key, currentDate))
        .expand((entry) => entry.value)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF078798),
        title: const Text('eTherapy', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'Calendar',
                style: TextStyle(color: Color(0xFF06013F), fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDate,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return appointments.keys.any((appointmentDate) => isSameDay(appointmentDate, day));
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Color(0xFF06013F), fontSize: 18, fontWeight: FontWeight.w600),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (appointments.containsKey(date)) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        width: 8.0,
                        height: 8.0,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Upcoming Appointments',
                style: TextStyle(color: Color(0xFF06013F), fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
            if (_getUpcomingAppointments().isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20, left: 27),
                child: Text(
                  'No upcoming appointments.',
                  style: TextStyle(
                    color: Color.fromRGBO(110, 181, 193, 1.0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ..._getUpcomingAppointments().map(
                  (appointment) => AppointmentCard(
                date: appointment.date,
                time: appointment.time,
                onReschedule: () => _onReschedule(appointment),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReschedule(Appointment appointment) async {
    if (availableAppointments.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Available Slots'),
          content: const Text('No available slots at the moment. Please try again later.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a New Time Slot'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableAppointments.entries.expand((entry) {
              return entry.value.map((appointment) => ListTile(
                title: Text('${entry.key.toLocal().toString().split(' ')[0]} at ${appointment.time}'),
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  _confirmReschedule(appointment, entry.key, appointment.time);
                },
              ));
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _confirmReschedule(Appointment oldAppointment, DateTime newDate, String newTime) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String oldFormattedDate = oldAppointment.date.toString().split(' ')[0];
    String newFormattedDate = newDate.toString().split(' ')[0];

    try {
      // Fetch assigned doctor ID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String assignedDoctorId = userDoc['assignedDoctorId'];

      // 1. Check if the selected slot is still available
      QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(assignedDoctorId)
          .collection('slots')
          .where('date', isEqualTo: newFormattedDate)
          .where('time', isEqualTo: newTime)
          .get();

      if (slotSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected time slot is no longer available.')),
        );
        return;
      }

      // 2. Remove old appointment from user's booked appointments
      QuerySnapshot oldSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .where('date', isEqualTo: oldFormattedDate)
          .where('time', isEqualTo: oldAppointment.time)
          .get();

      for (var doc in oldSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3. Add new appointment
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .add({
        'date': newFormattedDate,
        'time': newTime,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment rescheduled successfully.')),
      );
      setState(() {
        _fetchAppointments();
      });
    } catch (e) {
      print("Error confirming reschedule: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error rescheduling appointment.')),
      );
    }
  }
}

class AppointmentCard extends StatelessWidget {
  final DateTime date;
  final String time;
  final VoidCallback onReschedule;

  const AppointmentCard({
    Key? key,
    required this.date,
    required this.time,
    required this.onReschedule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '${date.toLocal().toString().split(' ')[0]} at $time',
        style: TextStyle(fontSize: 16),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onReschedule,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class Appointment {
//   final DateTime date;
//   final String time;
//   final DateTime timestamp;
//
//   Appointment({required this.date, required this.time, required this.timestamp});
// }
//
// class AppPage extends StatefulWidget {
//   @override
//   State<AppPage> createState() => _AppPageState();
// }
//
// class _AppPageState extends State<AppPage> {
//   DateTime _focusedDate = DateTime.now();
//   Map<DateTime, List<Appointment>> appointments = {};
//   Map<DateTime, List<Appointment>> availableAppointments = {}; // Add this line
//
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAppointments();
//     _fetchAvailableSlots();
//   }
//
//   Future<void> _fetchAvailableSlots() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     DocumentSnapshot userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .get();
//
//     if (!userDoc.exists || !userDoc.data().toString().contains('assignedDoctorId')) {
//       return;
//     }
//
//     String assignedDoctorId = userDoc['assignedDoctorId'];
//     print("Doctor ID: $assignedDoctorId");
//
//     QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(assignedDoctorId)
//         .collection('slots')
//         .get();
//
//     if (slotSnapshot.docs.isEmpty) {
//       print("No slots found for doctor: $assignedDoctorId");
//     }
//
//     Map<DateTime, List<Appointment>> tempAppointments = {};
//
//     for (var doc in slotSnapshot.docs) {
//       if (doc.data() is Map<String, dynamic>) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//
//         if (data.containsKey('date') && data.containsKey('time')) {
//           String dateString = data['date'];
//           String time = data['time'];
//           // Check if 'timestamp' exists and is of type Timestamp
//           DateTime? timestamp;
//           if (data.containsKey('timestamp') && data['timestamp'] is Timestamp) {
//             timestamp = (data['timestamp'] as Timestamp).toDate();
//           }
//
//           try {
//             List<String> dateParts = dateString.split('-');
//             DateTime date = DateTime(
//               int.parse(dateParts[0]),
//               int.parse(dateParts[1]),
//               int.parse(dateParts[2]),
//             );
//
//             // Normalize date to remove time component
//             DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//
//             if (!tempAppointments.containsKey(normalizedDate)) {
//               tempAppointments[normalizedDate] = [];
//             }
//             tempAppointments[normalizedDate]!.add(
//               Appointment(
//                 time: time,
//                 timestamp: timestamp ?? DateTime.now(),  // Provide a default value if null
//                 date: date,
//               ),
//             );
//             } catch (e) {
//             print("Error parsing date: $dateString - $e");
//           }
//         } else {
//           print("Invalid slot document: $doc");
//         }
//       }
//     }
//
//     setState(() {
//       availableAppointments = tempAppointments;
//     });
//   }
//   Future<void> _fetchAppointments() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('appointments')
//           .get();
//
//       Map<DateTime, List<Appointment>> loadedAppointments = {};
//       for (var doc in snapshot.docs) {
//         try {
//           // Parse date and normalize it to midnight
//           DateTime date = DateTime.parse(doc['date']);
//           DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//
//           // Extract time
//           String time = doc['time'];
//
//           // Parse timestamp
//           Timestamp timestamp = doc['timestamp'];
//           DateTime timestampDate = timestamp.toDate();
//
//           // Create appointment object
//           Appointment appointment = Appointment(
//             date: normalizedDate,
//             time: time,
//             timestamp: timestampDate,
//           );
//
//           // Store in map
//           loadedAppointments.putIfAbsent(normalizedDate, () => []).add(appointment);
//         } catch (e) {
//           print("Error parsing appointment: ${doc.data()}, Error: $e");
//         }
//       }
//
//       setState(() {
//         appointments = loadedAppointments;
//       });
//     }
//   }
//
//   List<Appointment> _getUpcomingAppointments() {
//     DateTime currentDate = DateTime.now();
//
//     return appointments.entries
//         .where((entry) => entry.key.isAfter(currentDate) || isSameDay(entry.key, currentDate))
//         .expand((entry) => entry.value)
//         .toList()
//       ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF078798),
//         title: const Text('eTherapy', style: TextStyle(color: Colors.white)),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             const Padding(
//               padding: EdgeInsets.all(10.0),
//               child: Text(
//                 'Calendar',
//                 style: TextStyle(color: Color(0xFF06013F), fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//             ),
//             TableCalendar(
//               firstDay: DateTime.utc(2020, 1, 1),
//               lastDay: DateTime.utc(2030, 12, 31),
//               focusedDay: _focusedDate,
//               calendarFormat: CalendarFormat.month,
//               selectedDayPredicate: (day) {
//                 return appointments.keys.any((appointmentDate) => isSameDay(appointmentDate, day));
//               },
//               headerStyle: const HeaderStyle(
//                 formatButtonVisible: false,
//                 titleCentered: true,
//                 titleTextStyle: TextStyle(color: Color(0xFF06013F), fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               calendarBuilders: CalendarBuilders(
//                 markerBuilder: (context, date, events) {
//                   if (appointments.containsKey(date)) {
//                     return Positioned(
//                       right: 1,
//                       bottom: 1,
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         width: 8.0,
//                         height: 8.0,
//                       ),
//                     );
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.all(20.0),
//               child: Text(
//                 'Upcoming Appointments',
//                 style: TextStyle(color: Color(0xFF06013F), fontSize: 24, fontWeight: FontWeight.w600),
//               ),
//             ),
//             if (_getUpcomingAppointments().isEmpty)
//               const Padding(
//                 padding: EdgeInsets.only(top: 20, left: 27),
//                 child: Text(
//                   'No upcoming appointments.',
//                   style: TextStyle(
//                     color: Color.fromRGBO(110, 181, 193, 1.0),
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ..._getUpcomingAppointments().map(
//                   (appointment) => AppointmentCard(
//                 date: appointment.date,
//                 time: appointment.time,
//                 onReschedule: () => _onReschedule(appointment),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   void _onReschedule(Appointment appointment) async {
//
//     if (availableAppointments.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('No Available Slots'),
//           content: const Text('No available slots at the moment. Please try again later.'),
//           actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
//         ),
//       );
//       return;
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Select a New Time Slot'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: availableAppointments.entries.expand((entry) {
//               return entry.value.map((appointment) => ListTile(
//                 title: Text('${entry.key.toLocal().toString().split(' ')[0]} at ${appointment.time}'),
//                 onTap: () {
//                   Navigator.pop(context); // Close dialog
//                   _confirmReschedule(appointment, entry.key, appointment.time);
//                 },
//               ));
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
//   void _confirmReschedule(Appointment oldAppointment, DateTime newDate, String newTime) async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     String oldFormattedDate = oldAppointment.date.toString().split(' ')[0];
//     String newFormattedDate = newDate.toString().split(' ')[0];
//
//     try {
//       // Fetch assigned doctor ID
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//       String assignedDoctorId = userDoc['assignedDoctorId'];
//
//       // 1. Check if the selected slot is still available
//       QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(assignedDoctorId)
//           .collection('slots')
//           .where('date', isEqualTo: newFormattedDate)
//           .where('time', isEqualTo: newTime)
//           .get();
//
//       if (slotSnapshot.docs.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Selected time slot is no longer available.')),
//         );
//         return;
//       }
//
//       // 2. Remove old appointment from user's booked appointments
//       QuerySnapshot oldSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('appointments')
//           .where('date', isEqualTo: oldFormattedDate)
//           .where('time', isEqualTo: oldAppointment.time)
//           .get();
//
//       for (var doc in oldSnapshot.docs) {
//         await doc.reference.delete();
//       }
//
//       // 3. Add old appointment back to available slots
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(assignedDoctorId)
//           .collection('slots')
//           .add({
//         'date': oldFormattedDate,
//         'time': oldAppointment.time,
//       });
//
//       // 4. Add new appointment to user's booked appointments
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('appointments')
//           .add({
//         'date': newFormattedDate,
//         'time': newTime,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       // 5. Remove new appointment from available slots
//       for (var doc in slotSnapshot.docs) {
//         await doc.reference.delete();
//       }
//
//       // 6. Refresh UI
//       _fetchAppointments();
//       _fetchAvailableSlots();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Appointment rescheduled successfully!')),
//       );
//
//       Navigator.pop(context); // Close dialog
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Reschedule failed: $e')),
//       );
//     }
//   }
// }
//
// class AppointmentCard extends StatelessWidget {
//   final DateTime date;
//   final String time;
//   final VoidCallback onReschedule;
//
//   const AppointmentCard({required this.date, required this.time, required this.onReschedule});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18),
//           color: const Color(0xFF078798),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               offset: const Offset(4, 4),
//               blurRadius: 8,
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Date: ${date.toLocal().toString().split(' ')[0]}',
//                       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Time: $time',
//                       style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
//                     ),
//                   ],
//                 ),
//               ),
//               GestureDetector(
//                 onTap: onReschedule,
//                 child: Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(Icons.edit_calendar, color: Color(0xFF078798), size: 24),
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


/// idk
// void _confirmReschedule(Appointment oldAppointment, DateTime newDate, String newTime) async {
//   User? user = FirebaseAuth.instance.currentUser;
//   if (user == null) return;
//
//   String oldFormattedDate = oldAppointment.date.toString().split(' ')[0];
//   String newFormattedDate = newDate.toString().split(' ')[0];
//
//   try {
//     // Fetch assigned doctor ID
//     DocumentSnapshot userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .get();
//     String assignedDoctorId = userDoc['assignedDoctorId'];
//
//     // 1. Add old appointment back to available slots
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(assignedDoctorId)
//         .collection('slots')
//         .add({
//       'date': oldFormattedDate,
//       'time': oldAppointment.time,
//     });
//
//     // 2. Remove old appointment from user's booked appointments
//     QuerySnapshot oldSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('appointments')
//         .where('date', isEqualTo: oldFormattedDate)
//         .where('time', isEqualTo: oldAppointment.time)
//         .get();
//
//     for (var doc in oldSnapshot.docs) {
//       await doc.reference.delete();
//     }
//
//     // 3. Add new appointment to user's booked appointments
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('appointments')
//         .add({
//       'date': newFormattedDate,
//       'time': newTime,
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//
//     // 4. Remove new appointment from available slots
//     QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(assignedDoctorId)
//         .collection('slots')
//         .where('date', isEqualTo: newFormattedDate)
//         .where('time', isEqualTo: newTime)
//         .get();
//
//     for (var doc in slotSnapshot.docs) {
//       await doc.reference.delete();
//     }
//
//     Navigator.pop(context); // Close dialog
//     _fetchAppointments(); // Refresh list
//     _fetchAvailableSlots(); // Refresh slots
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Reschedule failed: $e')),
//     );
//   }
// }


/// works wihtout res
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class Appointment {
//   final DateTime date;
//   final String time;
//   final DateTime timestamp;
//
//   Appointment({required this.date, required this.time, required this.timestamp});
// }
//
// class AppPage extends StatefulWidget {
//   @override
//   State<AppPage> createState() => _AppPageState();
// }
//
// class _AppPageState extends State<AppPage> {
//   DateTime _focusedDate = DateTime.now();
//   Map<DateTime, List<Appointment>> appointments = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAppointments();
//   }
//
//   Future<void> _fetchAppointments() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('appointments')
//           .get();
//
//       Map<DateTime, List<Appointment>> loadedAppointments = {};
//       for (var doc in snapshot.docs) {
//         try {
//           // Parse date and normalize it to midnight
//           DateTime date = DateTime.parse(doc['date']);
//           DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//
//           // Extract time
//           String time = doc['time'];
//
//           // Parse timestamp
//           Timestamp timestamp = doc['timestamp'];
//           DateTime timestampDate = timestamp.toDate();
//
//           // Create appointment object
//           Appointment appointment = Appointment(
//             date: normalizedDate,
//             time: time,
//             timestamp: timestampDate,
//           );
//
//           // Store in map
//           loadedAppointments.putIfAbsent(normalizedDate, () => []).add(appointment);
//         } catch (e) {
//           print("Error parsing appointment: ${doc.data()}, Error: $e");
//         }
//       }
//
//       setState(() {
//         appointments = loadedAppointments;
//       });
//     }
//   }
//
//   List<Appointment> _getUpcomingAppointments() {
//     DateTime currentDate = DateTime.now();
//
//     return appointments.entries
//         .where((entry) => entry.key.isAfter(currentDate) || isSameDay(entry.key, currentDate))
//         .expand((entry) => entry.value)
//         .toList()
//       ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF078798),
//         title: const Text('eTherapy', style: TextStyle(color: Colors.white)),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: const Text(
//                 'Calendar',
//                 style: TextStyle(color: Color(0xFF06013F), fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//             ),
//             TableCalendar(
//               firstDay: DateTime.utc(2020, 1, 1),
//               lastDay: DateTime.utc(2030, 12, 31),
//               focusedDay: _focusedDate,
//               calendarFormat: CalendarFormat.month,
//               selectedDayPredicate: (day) {
//                 return appointments.keys.any((appointmentDate) => isSameDay(appointmentDate, day));
//               },
//               headerStyle: const HeaderStyle(
//                 formatButtonVisible: false,
//                 titleCentered: true,
//                 titleTextStyle: TextStyle(color: Color(0xFF06013F), fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               calendarBuilders: CalendarBuilders(
//                 markerBuilder: (context, date, events) {
//                   if (appointments.containsKey(date)) {
//                     return Positioned(
//                       right: 1,
//                       bottom: 1,
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         width: 8.0,
//                         height: 8.0,
//                       ),
//                     );
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: const Text(
//                 'Upcoming Appointments',
//                 style: TextStyle(color: Color(0xFF06013F), fontSize: 24, fontWeight: FontWeight.w600),
//               ),
//             ),
//             if (_getUpcomingAppointments().isEmpty)
//               const Padding(
//                 padding: EdgeInsets.only(top: 20, left: 27),
//                 child: Text(
//                   'No upcoming appointments.',
//                   style: TextStyle(
//                     color: Color.fromRGBO(110, 181, 193, 1.0),
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ..._getUpcomingAppointments().map(
//                   (appointment) => AppointmentCard(
//                 date: appointment.date,
//                 time: appointment.time,
//                 onReschedule: () => _onReschedule(appointment),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _onReschedule(Appointment appointment) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Reschedule Appointment'),
//         content: Text('Reschedule the appointment on ${appointment.date.toLocal().toString().split(' ')[0]} at ${appointment.time}.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Reschedule')),
//         ],
//       ),
//     );
//   }
// }
//
// class AppointmentCard extends StatelessWidget {
//   final DateTime date;
//   final String time;
//   final VoidCallback onReschedule;
//
//   const AppointmentCard({required this.date, required this.time, required this.onReschedule});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18),
//           color: const Color(0xFF078798),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               offset: const Offset(4, 4),
//               blurRadius: 8,
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Date: ${date.toLocal().toString().split(' ')[0]}',
//                       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Time: $time',
//                       style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
//                     ),
//                   ],
//                 ),
//               ),
//               GestureDetector(
//                 onTap: onReschedule,
//                 child: Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(Icons.edit_calendar, color: Color(0xFF078798), size: 24),
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



/// normal
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class Appointment {
//   final DateTime date;
//   final String time;
//
//   Appointment({required this.date, required this.time});
// }
//
// class AppPage extends StatefulWidget {
//   @override
//   State<AppPage> createState() => _AppPageState();
// }
//
// class _AppPageState extends State<AppPage> {
//   DateTime _focusedDate = DateTime.now();
//   Map<DateTime, List<Appointment>> appointments = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAppointments();
//   }
//
//   Future<void> _fetchAppointments() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('appointments')
//           .get();
//
//       Map<DateTime, List<Appointment>> loadedAppointments = {};
//       for (var doc in snapshot.docs) {
//         try {
//           DateTime date = DateTime.parse(doc['date']);
//           Appointment appointment = Appointment(
//             date: date,
//             time: doc['time'],
//           );
//
//           loadedAppointments.putIfAbsent(date, () => []).add(appointment);
//         } catch (e) {
//           print("Error parsing date: ${doc['date']}, Error: $e");
//         }
//       }
//
//       setState(() {
//         appointments = loadedAppointments;
//       });
//     }
//   }
//
//   List<Appointment> _getUpcomingAppointments() {
//     DateTime currentDate = DateTime.now();
//     List<Appointment> upcomingAppointments = appointments.entries
//         .where((entry) => entry.key.isAfter(currentDate) || isSameDay(entry.key, currentDate))
//         .expand((entry) => entry.value)
//         .toList();
//
//     upcomingAppointments.sort((a, b) => a.date.compareTo(b.date));
//     return upcomingAppointments;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF078798),
//         title: const Text('eTherapy', style: TextStyle(color: Colors.white)),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: const Text(
//                 'Calendar',
//                 style: TextStyle(color: Color(0xFF06013F), fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//             ),
//             TableCalendar(
//               firstDay: DateTime.utc(2020, 1, 1),
//               lastDay: DateTime.utc(2030, 12, 31),
//               focusedDay: _focusedDate,
//               calendarFormat: CalendarFormat.month,
//               selectedDayPredicate: (day) {
//                 return appointments.keys.any((appointmentDate) => isSameDay(appointmentDate, day));
//               },
//               headerStyle: const HeaderStyle(
//                 formatButtonVisible: false,
//                 titleCentered: true,
//                 titleTextStyle: TextStyle(color: Color(0xFF06013F), fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               calendarBuilders: CalendarBuilders(
//                 markerBuilder: (context, date, events) {
//                   if (appointments.containsKey(date)) {
//                     return Positioned(
//                       right: 1,
//                       bottom: 1,
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         width: 8.0,
//                         height: 8.0,
//                       ),
//                     );
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: const Text(
//                 'Upcoming Appointments',
//                 style: TextStyle(color: Color(0xFF06013F), fontSize: 24, fontWeight: FontWeight.w600),
//               ),
//             ),
//             if (_getUpcomingAppointments().isEmpty)
//               const Padding(
//                 padding: EdgeInsets.only(top: 20, left: 27),
//                 child: Text(
//                   'No upcoming appointments.',
//                   style: TextStyle(
//                     color: Color.fromRGBO(110, 181, 193, 1.0),
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ..._getUpcomingAppointments().map(
//                   (appointment) => AppointmentCard(
//                 date: appointment.date,
//                 time: appointment.time,
//                 onReschedule: () => _onReschedule(appointment),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _onReschedule(Appointment appointment) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Reschedule Appointment'),
//         content: Text('Reschedule the appointment on ${appointment.date.toLocal().toString().split(' ')[0]} at ${appointment.time}.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Reschedule')),
//         ],
//       ),
//     );
//   }
// }
//
// class AppointmentCard extends StatelessWidget {
//   final DateTime date;
//   final String time;
//   final VoidCallback onReschedule;
//
//   const AppointmentCard({required this.date, required this.time, required this.onReschedule});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18),
//           color: const Color(0xFF078798),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               offset: const Offset(4, 4),
//               blurRadius: 8,
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Date: ${date.toLocal().toString().split(' ')[0]}',
//                       style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Time: $time',
//                       style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
//                     ),
//                   ],
//                 ),
//               ),
//               GestureDetector(
//                 onTap: onReschedule,
//                 child: Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(Icons.edit_calendar, color: Color(0xFF078798), size: 24),
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


/// old
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class Appointment {
//   final String date;
//   final String time;
//
//   Appointment({required this.date, required this.time});
// }
//
// class AppPage extends StatefulWidget {
//   @override
//   State<AppPage> createState() => _AppPageState();
// }
//
// class _AppPageState extends State<AppPage> {
//   DateTime _focusedDate = DateTime.now();
//   Map<DateTime, List<Appointment>> appointments = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAppointments();
//   }
//
//   Future<void> _fetchAppointments() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('appointments')
//           .get();
//
//       Map<DateTime, List<Appointment>> loadedAppointments = {};
//       for (var doc in snapshot.docs) {
//         DateTime date = DateTime.parse(doc['date']);
//         Appointment appointment = Appointment(
//           date: doc['date'],
//           time: doc['time'],
//         );
//
//         if (loadedAppointments[date] == null) {
//           loadedAppointments[date] = [];
//         }
//         loadedAppointments[date]!.add(appointment);
//       }
//
//       setState(() {
//         appointments = loadedAppointments;
//       });
//     }
//   }
//
//   List<Appointment> _getUpcomingAppointments() {
//     DateTime currentDate = DateTime.now();
//     List<Appointment> upcomingAppointments = appointments.entries
//         .where((entry) => entry.key.isAfter(currentDate) || entry.key.isAtSameMomentAs(currentDate))
//         .expand((entry) => entry.value)
//         .toList();
//
//     upcomingAppointments.sort((a, b) => _parseDateString(a.date).compareTo(_parseDateString(b.date)));
//     return upcomingAppointments;
//   }
//
//   DateTime _parseDateString(String date) {
//     List<String> dateParts = date.split('-');
//     return DateTime(
//       int.parse(dateParts[0]),
//       int.parse(dateParts[1]),
//       int.parse(dateParts[2]),
//     );
//   }
//
//   List<DateTime> _getAppointmentDates() {
//     return appointments.keys.toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF078798),
//         title: const Text('eTherapy', style: TextStyle(color: Colors.white)),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: const Text(
//                 'Calendar',
//                 style: TextStyle(color: Color(0xFF06013F), fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//             ),
//             TableCalendar(
//               firstDay: DateTime.utc(2020, 1, 1),
//               lastDay: DateTime.utc(2030, 12, 31),
//               focusedDay: _focusedDate,
//               calendarFormat: CalendarFormat.month,
//               selectedDayPredicate: (day) => _getAppointmentDates().any(
//                     (appointmentDate) => appointmentDate.year == day.year &&
//                     appointmentDate.month == day.month &&
//                     appointmentDate.day == day.day,
//               ),
//               headerStyle: const HeaderStyle(
//                 formatButtonVisible: false,
//                 titleCentered: true,
//                 titleTextStyle: TextStyle(color: Color(0xFF06013F), fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//               calendarBuilders: CalendarBuilders(
//                 markerBuilder: (context, date, events) {
//                   if (appointments[date] != null) {
//                     return Positioned(
//                       right: 1,
//                       bottom: 1,
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         width: 8.0,
//                         height: 8.0,
//                       ),
//                     );
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: const Text(
//                 'Upcoming Appointments',
//                 style: TextStyle(color: Color(0xFF06013F), fontSize: 24, fontWeight: FontWeight.w600),
//               ),
//             ),
//             if (_getUpcomingAppointments().isEmpty)
//               const Padding(
//                 padding: EdgeInsets.only(top: 20, left: 27),
//                 child: Text('No upcoming appointments.',
//                     style: TextStyle(color: Color.fromRGBO(110, 181, 193, 1.0), fontSize: 20, fontWeight: FontWeight.bold)),
//               ),
//             ..._getUpcomingAppointments().map(
//                   (appointment) => AppointmentCard(
//                 date: appointment.date,
//                 time: appointment.time,
//                 onReschedule: () => _onReschedule(appointment),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _onReschedule(Appointment appointment) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Reschedule Appointment'),
//         content: Text('Reschedule the appointment on ${appointment.date} at ${appointment.time}.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Reschedule')),
//         ],
//       ),
//     );
//   }
// }
//
// class AppointmentCard extends StatelessWidget {
//   final String date;
//   final String time;
//   final VoidCallback onReschedule;
//
//   const AppointmentCard({required this.date, required this.time, required this.onReschedule});
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(18),
//           color: const Color(0xFF078798),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               offset: const Offset(4, 4),
//               blurRadius: 8,
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Date: $date',
//                         style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 4),
//                     Text('Time: $time',
//                         style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal)),
//                   ],
//                 ),
//               ),
//               GestureDetector(
//                 onTap: onReschedule,
//                 child: Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(Icons.edit_calendar, color: Color(0xFF078798), size: 24),
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
//
//
