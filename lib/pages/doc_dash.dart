import 'package:app/pages/slots.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _appointments = {};

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  /// Fetches Appointments from Firestore
  void _fetchAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .where('assignedDoctorId', isEqualTo: user.uid)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        String patientId = doc.id;
        String patientName = doc['name'] ?? 'Unknown';

        FirebaseFirestore.instance
            .collection('users')
            .doc(patientId)
            .collection('appointments')
            .get()
            .then((appointmentSnapshot) {
          for (var appt in appointmentSnapshot.docs) {
            var data = appt.data();
            print("Fetched Data: $data"); // Debugging print

            if (data.containsKey('date') && data.containsKey('time')) {
              String dateStr = data['date'];  // "2025-4-9"
              String timeStr = data['time'];  // "12:0"
              DateTime date;

              try {
                // Normalize the date string to ensure the month and day are two digits
                List<String> dateParts = dateStr.split('-');
                String year = dateParts[0];
                String month = dateParts[1].padLeft(2, '0'); // Ensure 2-digit month
                String day = dateParts[2].padLeft(2, '0'); // Ensure 2-digit day

                String normalizedDateStr = '$year-$month-$day'; // "2025-04-09"
                // Parse the normalized date string
                DateTime parsedDate = DateTime.parse(normalizedDateStr);

                // Parse the time string and combine it with the parsed date
                List<String> timeParts = timeStr.split(":");
                DateTime finalDateTime = DateTime(
                  parsedDate.year,
                  parsedDate.month,
                  parsedDate.day,
                  int.parse(timeParts[0]),  // hour
                  int.parse(timeParts[1]),  // minute
                );

                // Store the formatted date for display
                DateTime formattedDate = DateTime(finalDateTime.year, finalDateTime.month, finalDateTime.day);

                // Fetch timestamp if available for event logging or time reference
                Timestamp timestamp = appt['timestamp'];
                DateTime timestampDateTime = timestamp.toDate();

                // Debug print for fetched data and timestamp
                print("Fetched Appointment: $formattedDate at $timeStr, Timestamp: $timestampDateTime");

                setState(() {
                  if (_appointments[formattedDate] == null) {
                    _appointments[formattedDate] = [];
                  }
                  _appointments[formattedDate]!.add({
                    'patientName': patientName,
                    'time': timeStr,
                    'session': data['session'] ?? 'General',
                    'timestamp': timestampDateTime,
                  });
                });
              } catch (e) {
                print("Error parsing date or time: $dateStr, $timeStr - $e");
              }
            }
          }
        }).catchError((error) => print("Error fetching appointments: $error"));
      }
    }).catchError((error) => print("Error fetching patients: $error"));
  }

  /// Add a New Slot for Appointments
  void _addSlot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    ).then((date) async {
      if (date != null) {
        selectedDate = date;
        await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        ).then((time) {
          if (time != null) {
            selectedTime = time;
          }
        });
      }
    });

    if (selectedDate != null && selectedTime != null) {
      DateTime appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('slots')
          .add({
        'timestamp': Timestamp.fromDate(appointmentDateTime),
        'time': "${selectedTime!.hour}:${selectedTime!.minute}",
      });

      print("Slot Added: $appointmentDateTime");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointments Calendar',
                  style: TextStyle(
                    color: Color(0xFF078798),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, size: 30, color: Color(0xFF078798)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Slots()),
                    );
                  },
                ),
              ],
            ),

            /// Calendar
            TableCalendar(
              focusedDay: _selectedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
              eventLoader: (day) =>
              _appointments[DateTime(day.year, day.month, day.day)] ?? [],
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue[200],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF078798),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            const Center(
              child: Text(
                'Appointments',
                style: TextStyle(
                  color: Color(0xFF078798),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            /// Appointment List for Selected Date
            Expanded(
              child: _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] != null
                  ? ListView.builder(
                itemCount: _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]!.length,
                itemBuilder: (context, index) {
                  var appointment = _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]![index];
                  return AppointmentCard(
                    patientName: appointment['patientName'],
                    time: appointment['time'],
                    session: appointment['session'],
                  );
                },
              )
                  : const Center(
                child: Text(
                  'No appointments for this day.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Appointment Card UI
class AppointmentCard extends StatelessWidget {
  final String patientName;
  final String time;
  final String session;

  const AppointmentCard({
    Key? key,
    required this.patientName,
    required this.time,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFF078798)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Time : $time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Patient: $patientName", style: TextStyle(fontSize: 14, color: Colors.black54)),
                Text("Session: $session", style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


///
// import 'package:app/pages/slots.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class DoctorDashboard extends StatefulWidget {
//   @override
//   _DoctorDashboardState createState() => _DoctorDashboardState();
// }
//
// class _DoctorDashboardState extends State<DoctorDashboard> {
//   DateTime _selectedDay = DateTime.now();
//   Map<DateTime, List<Map<String, dynamic>>> _appointments = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAppointments();
//   }
//
//   /// Fetches Appointments from Firestore
//   void _fetchAppointments() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     FirebaseFirestore.instance
//         .collection('users')
//         .where('assignedDoctorId', isEqualTo: user.uid)
//         .get()
//         .then((querySnapshot) {
//       for (var doc in querySnapshot.docs) {
//         String patientId = doc.id;
//         String patientName = doc['name'] ?? 'Unknown';
//
//         FirebaseFirestore.instance
//             .collection('users')
//             .doc(patientId)
//             .collection('appointments')
//             .get()
//             .then((appointmentSnapshot) {
//           for (var appt in appointmentSnapshot.docs) {
//             var data = appt.data();
//             print("Fetched Data: $data"); // Debugging print
//
//             if (data.containsKey('date')) {
//               DateTime date;
//
//               if (data['date'] is Timestamp) {
//                 date = (data['date'] as Timestamp).toDate();
//               } else if (data['date'] is String) {
//                 try {
//                   date = DateTime.parse(data['date']);
//                 } catch (e) {
//                   print("Error parsing date: ${data['date']} - $e");
//                   continue;
//                 }
//               } else {
//                 print("Invalid date format: ${data['date']}");
//                 continue;
//               }
//
//               DateTime formattedDate = DateTime(date.year, date.month, date.day);
//
//               setState(() {
//                 if (_appointments[formattedDate] == null) {
//                   _appointments[formattedDate] = [];
//                 }
//                 _appointments[formattedDate]!.add({
//                   'patientName': patientName,
//                   'time': data['time'] ?? 'Unknown',
//                   'session': data['session'] ?? 'General',
//                 });
//               });
//
//               print("Fetched Appointment: $formattedDate - ${data['time']}");
//             }
//           }
//         }).catchError((error) => print("Error fetching appointments: $error"));
//       }
//     }).catchError((error) => print("Error fetching patients: $error"));
//   }
//
//   /// Add a New Slot for Appointments
//   void _addSlot() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     DateTime? selectedDate;
//     TimeOfDay? selectedTime;
//
//     await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2030),
//     ).then((date) async {
//       if (date != null) {
//         selectedDate = date;
//         await showTimePicker(
//           context: context,
//           initialTime: TimeOfDay.now(),
//         ).then((time) {
//           if (time != null) {
//             selectedTime = time;
//           }
//         });
//       }
//     });
//
//     if (selectedDate != null && selectedTime != null) {
//       DateTime appointmentDateTime = DateTime(
//         selectedDate!.year,
//         selectedDate!.month,
//         selectedDate!.day,
//         selectedTime!.hour,
//         selectedTime!.minute,
//       );
//
//       FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('slots')
//           .add({
//         'timestamp': Timestamp.fromDate(appointmentDateTime),
//         'time': "${selectedTime!.hour}:${selectedTime!.minute}",
//       });
//
//       print("Slot Added: $appointmentDateTime");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Appointments Calendar',
//                   style: TextStyle(
//                     color: Color(0xFF078798),
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.add_circle, size: 30, color: Color(0xFF078798)),
//                   onPressed: (){
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => Slots()),
//                     );
//                   },
//                 ),
//               ],
//             ),
//
//             /// Calendar
//             TableCalendar(
//               focusedDay: _selectedDay,
//               firstDay: DateTime.utc(2020, 1, 1),
//               lastDay: DateTime.utc(2030, 12, 31),
//               calendarFormat: CalendarFormat.month,
//               selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//               onDaySelected: (selectedDay, focusedDay) {
//                 setState(() {
//                   _selectedDay = selectedDay;
//                 });
//               },
//               eventLoader: (day) => _appointments[DateTime(day.year, day.month, day.day)] ?? [],
//               calendarStyle: CalendarStyle(
//                 todayDecoration: BoxDecoration(
//                   color: Colors.blue[200],
//                   shape: BoxShape.circle,
//                 ),
//                 selectedDecoration: const BoxDecoration(
//                   color: Color(0xFF078798),
//                   shape: BoxShape.circle,
//                 ),
//                 markerDecoration: const BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//
//             const Center(
//               child: Text(
//                 'Appointments',
//                 style: TextStyle(
//                   color: Color(0xFF078798),
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//
//             /// Appointment List for Selected Date
//             Expanded(
//               child: _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] != null
//                   ? ListView.builder(
//                 itemCount: _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]!.length,
//                 itemBuilder: (context, index) {
//                   var appointment = _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]![index];
//                   return AppointmentCard(
//                     patientName: appointment['patientName'],
//                     time: appointment['time'],
//                     session: appointment['session'],
//                   );
//                 },
//               )
//                   : const Center(
//                 child: Text(
//                   'No appointments for this day.',
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
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
// /// Appointment Card UI
// class AppointmentCard extends StatelessWidget {
//   final String patientName;
//   final String time;
//   final String session;
//
//   const AppointmentCard({
//     Key? key,
//     required this.patientName,
//     required this.time,
//     required this.session,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 15),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Row(
//           children: [
//             Icon(Icons.calendar_today, color: Color(0xFF078798)),
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Time : $time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 Text("Patient: $patientName", style: TextStyle(fontSize: 14, color: Colors.black54)),
//                 Text("Session: $session", style: TextStyle(fontSize: 14, color: Colors.black54)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//



/// used to work
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class DoctorDashboard extends StatefulWidget {
//   @override
//   _DoctorDashboardState createState() => _DoctorDashboardState();
// }
//
// class _DoctorDashboardState extends State<DoctorDashboard> {
//   DateTime _selectedDay = DateTime.now();
//   Map<DateTime, List<Map<String, dynamic>>> _appointments = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAppointments();
//   }
//
//   /// Fetches Appointments from Firestore
//   void _fetchAppointments() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     FirebaseFirestore.instance
//         .collection('users')
//         .where('assignedDoctorId', isEqualTo: user.uid)
//         .get()
//         .then((querySnapshot) {
//       for (var doc in querySnapshot.docs) {
//         String patientId = doc.id;
//         String patientName = doc['name'] ?? 'Unknown';
//
//         FirebaseFirestore.instance
//             .collection('users')
//             .doc(patientId)
//             .collection('appointments')
//             .get()
//             .then((appointmentSnapshot) {
//           for (var appt in appointmentSnapshot.docs) {
//             var data = appt.data();
//
//             // Ensure timestamp exists and convert to DateTime
//             if (data.containsKey('timestamp') && data['timestamp'] is Timestamp) {
//               DateTime date = (data['timestamp'] as Timestamp).toDate();
//               DateTime formattedDate = DateTime(date.year, date.month, date.day);
//
//               setState(() {
//                 if (_appointments[formattedDate] == null) {
//                   _appointments[formattedDate] = [];
//                 }
//                 _appointments[formattedDate]!.add({
//                   'patientName': patientName,
//                   'time': data['time'] ?? 'Unknown',
//                   'session': data['session'] ?? 'General',
//                 });
//               });
//
//               // Debugging log
//               print("Fetched Appointment: $formattedDate - ${data['time']}");
//             } else {
//               print("Invalid timestamp format: ${data['timestamp']}");
//             }
//           }
//         }).catchError((error) => print("Error fetching appointments: $error"));
//       }
//     }).catchError((error) => print("Error fetching patients: $error"));
//   }
//
//   /// Add a New Slot for Appointments
//   void _addSlot() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     DateTime? selectedDate;
//     TimeOfDay? selectedTime;
//
//     await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2030),
//     ).then((date) async {
//       if (date != null) {
//         selectedDate = date;
//         await showTimePicker(
//           context: context,
//           initialTime: TimeOfDay.now(),
//         ).then((time) {
//           if (time != null) {
//             selectedTime = time;
//           }
//         });
//       }
//     });
//
//     if (selectedDate != null && selectedTime != null) {
//       DateTime appointmentDateTime = DateTime(
//         selectedDate!.year,
//         selectedDate!.month,
//         selectedDate!.day,
//         selectedTime!.hour,
//         selectedTime!.minute,
//       );
//
//       FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('slots')
//           .add({
//         'timestamp': Timestamp.fromDate(appointmentDateTime),
//         'time': "${selectedTime!.hour}:${selectedTime!.minute}",
//       });
//
//       print("Slot Added: $appointmentDateTime");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Appointments Calendar',
//                   style: TextStyle(
//                     color: Color(0xFF078798),
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.add_circle, size: 30, color: Color(0xFF078798)),
//                   onPressed: _addSlot,
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 20),
//
//             /// Calendar
//             TableCalendar(
//               focusedDay: _selectedDay,
//               firstDay: DateTime.utc(2020, 1, 1),
//               lastDay: DateTime.utc(2030, 12, 31),
//               calendarFormat: CalendarFormat.month,
//               selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//               onDaySelected: (selectedDay, focusedDay) {
//                 setState(() {
//                   _selectedDay = selectedDay;
//                 });
//               },
//               eventLoader: (day) => _appointments[DateTime(day.year, day.month, day.day)] ?? [],
//               calendarStyle: CalendarStyle(
//                 todayDecoration: BoxDecoration(
//                   color: Colors.blue[200],
//                   shape: BoxShape.circle,
//                 ),
//                 selectedDecoration: const BoxDecoration(
//                   color: Color(0xFF078798),
//                   shape: BoxShape.circle,
//                 ),
//                 markerDecoration: const BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//             const Center(
//               child: Text(
//                 'Appointments',
//                 style: TextStyle(
//                   color: Color(0xFF078798),
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             /// Appointment List for Selected Date
//             Expanded(
//               child: _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] != null
//                   ? ListView.builder(
//                 itemCount: _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]!.length,
//                 itemBuilder: (context, index) {
//                   var appointment = _appointments[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]![index];
//                   return AppointmentCard(
//                     patientName: appointment['patientName'],
//                     time: appointment['time'],
//                     session: appointment['session'],
//                   );
//                 },
//               )
//                   : const Center(
//                 child: Text(
//                   'No appointments for this day.',
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
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
// /// Appointment Card UI
// class AppointmentCard extends StatelessWidget {
//   final String patientName;
//   final String time;
//   final String session;
//
//   const AppointmentCard({
//     Key? key,
//     required this.patientName,
//     required this.time,
//     required this.session,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.only(bottom: 15),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Icon(Icons.calendar_today, color: Color(0xFF078798)),
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "$time",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   "Patient: $patientName",
//                   style: TextStyle(fontSize: 14, color: Colors.black54),
//                 ),
//                 Text(
//                   "Session: $session",
//                   style: TextStyle(fontSize: 14, color: Colors.black54),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//

/// normal
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
//
//
//
// class DoctorDashboard extends StatefulWidget {
//   @override
//   _DoctorDashboardState createState() => _DoctorDashboardState();
// }
//
// class _DoctorDashboardState extends State<DoctorDashboard> {
//   DateTime _selectedDay = DateTime.now();
//   Map<DateTime, List<Map<String, dynamic>>> _appointments = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAppointments();
//   }
//
//   void _fetchAppointments() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     FirebaseFirestore.instance
//         .collection('users')
//         .where('assignedDoctorId', isEqualTo: user.uid)
//         .get()
//         .then((querySnapshot) {
//       for (var doc in querySnapshot.docs) {
//         String patientId = doc.id;
//         String patientName = doc['name'] ?? 'Unknown';
//
//         FirebaseFirestore.instance
//             .collection('users')
//             .doc(patientId)
//             .collection('appointments')
//             .get()
//             .then((appointmentSnapshot) {
//           for (var appt in appointmentSnapshot.docs) {
//             var data = appt.data();
//             DateTime date = DateTime.parse(data['date']);
//
//             setState(() {
//               if (_appointments[date] == null) {
//                 _appointments[date] = [];
//               }
//               _appointments[date]!.add({
//                 'patientName': patientName,
//                 'time': data['time'] ?? 'Unknown',
//                 'session': data['session'] ?? 'General',
//               });
//             });
//           }
//         });
//       }
//     });
//   }
//
//
//   void _addSlot() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     DateTime? selectedDate;
//     TimeOfDay? selectedTime;
//
//     await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2030),
//     ).then((date) async {
//       if (date != null) {
//         selectedDate = date;
//         await showTimePicker(
//           context: context,
//           initialTime: TimeOfDay.now(),
//         ).then((time) {
//           if (time != null) {
//             selectedTime = time;
//           }
//         });
//       }
//     });
//
//     if (selectedDate != null && selectedTime != null) {
//       String formattedDate = "${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}";
//       String formattedTime = "${selectedTime!.hour}:${selectedTime!.minute}";
//
//       FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('slots')
//           .add({
//         'date': formattedDate,
//         'time': formattedTime,
//       });
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Appointments Calendar',
//                   style: TextStyle(
//                     color: Color(0xFF078798),
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.add_circle, size: 30, color: Color(0xFF078798)),
//                   onPressed: _addSlot,
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 20),
//
//             /// Calendar
//             TableCalendar(
//               focusedDay: _selectedDay,
//               firstDay: DateTime.utc(2020, 1, 1),
//               lastDay: DateTime.utc(2030, 12, 31),
//               calendarFormat: CalendarFormat.month,
//               selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//               onDaySelected: (selectedDay, focusedDay) {
//                 setState(() {
//                   _selectedDay = selectedDay;
//                 });
//               },
//               eventLoader: (day) => _appointments[day] ?? [],
//               calendarStyle: CalendarStyle(
//                 todayDecoration: BoxDecoration(
//                   color: Colors.blue[200],
//                   shape: BoxShape.circle,
//                 ),
//                 selectedDecoration: BoxDecoration(
//                   color: Color(0xFF078798),
//                   shape: BoxShape.circle,
//                 ),
//                 markerDecoration: BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             /// Appointment List for Selected Date
//             Expanded(
//               child: _appointments[_selectedDay] != null
//                   ? ListView.builder(
//                 itemCount: _appointments[_selectedDay]!.length,
//                 itemBuilder: (context, index) {
//                   var appointment = _appointments[_selectedDay]![index];
//                   return AppointmentCard(
//                     patientName: appointment['patientName'],
//                     time: appointment['time'],
//                     session: appointment['session'],
//                   );
//                 },
//               )
//                   : const Center(
//                 child: Text(
//                   'No appointments for this day.',
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
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
// /// Appointment Card UI
// class AppointmentCard extends StatelessWidget {
//   final String patientName;
//   final String time;
//   final String session;
//
//   const AppointmentCard({
//     Key? key,
//     required this.patientName,
//     required this.time,
//     required this.session,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.only(bottom: 15),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Icon(Icons.calendar_today, color: Color(0xFF078798)),
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "$time",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   "Patient: $patientName",
//                   style: TextStyle(fontSize: 14, color: Colors.black54),
//                 ),
//                 Text(
//                   "Session: $session",
//                   style: TextStyle(fontSize: 14, color: Colors.black54),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class AppointmentList extends StatelessWidget {
//   final List<Map<String, String>> appointments;
//
//   const AppointmentList({super.key, required this.appointments});
//
//   @override
//   Widget build(BuildContext context) {
//     if (appointments.isEmpty) {
//       return const Center(child: Text('No appointments for today.'));
//     }
//     return ListView.builder(
//       itemCount: appointments.length,
//       itemBuilder: (context, index) {
//         final appointment = appointments[index];
//         return Card(
//           child: ListTile(
//             title: Text(appointment['name'] ?? 'No name'),
//             subtitle: Text('${appointment['time']} - ${appointment['session']}'),
//             trailing: const Icon(Icons.arrow_forward),
//             onTap: () {
//               // Navigator.push(
//               //   context,
//               //   MaterialPageRoute(
//               //     builder: (context) => PatientDetails(),
//               //   ),
//               // );
//             },
//           ),
//         );
//       },
//     );
//   }
// }
