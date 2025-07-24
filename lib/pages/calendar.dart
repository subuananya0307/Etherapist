import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // For Date Formatting
import 'package:table_calendar/table_calendar.dart';
import 'home_page.dart';

class Appointment {
  final String time;

  Appointment({required this.time});
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  Map<DateTime, List<Appointment>> availableAppointments = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableSlots();
  }

  Future<void> _fetchAvailableSlots() async {
    setState(() {
      _isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists || userDoc['assignedDoctorId'] == null) {
      setState(() {
        _isLoading = false;
      });
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
      setState(() {
        _isLoading = false;
      });
      return;
    }

    Map<DateTime, List<Appointment>> tempAppointments = {};

    for (var doc in slotSnapshot.docs) {
      if (doc.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('date') && data.containsKey('time')) {
          String dateString = data['date'];
          String time = data['time'];

          try {
            List<String> dateParts = dateString.split('-');
            DateTime date = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );

            // Normalize date to remove time component
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);

            if (!tempAppointments.containsKey(normalizedDate)) {
              tempAppointments[normalizedDate] = [];
            }
            tempAppointments[normalizedDate]!.add(Appointment(time: time));
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
      _isLoading = false;
    });

    print("Available slots: $availableAppointments");
  }

  Future<void> _bookAppointment(Appointment appointment) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDate == null) return;

    // Ensure the date format is "YYYY-M-D" (matching Firestore)
    String formattedDate = DateFormat('yyyy-M-d').format(_selectedDate!);

    try {
      // Add appointment to the user's appointments collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .add({
        'date': formattedDate,
        'time': appointment.time,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get the assigned doctor's ID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String assignedDoctorId = userDoc['assignedDoctorId'];

      // Find the slot in the doctor's collection
      QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(assignedDoctorId)
          .collection('slots')
          .where('date', isEqualTo: formattedDate)
          .where('time', isEqualTo: appointment.time)
          .get();

      // If the slot is found, remove it
      if (slotSnapshot.docs.isNotEmpty) {
        for (var doc in slotSnapshot.docs) {
          await doc.reference.delete();
          print("Slot removed from doctor's available slots.");
        }
      } else {
        print("No matching slot found for doctor.");
      }

      // Fetch available slots again to update the UI
      _fetchAvailableSlots();

      // Close the booking screen and show confirmation
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked for ${appointment.time}'),
          backgroundColor: Color(0xFF078798),
        ),
      );
    } catch (e) {
      // Show error message if appointment booking fails
      print("Error booking appointment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
          icon: Icon(Icons.home_filled),
          color: Colors.white,
        ),
        backgroundColor: const Color(0xFF078798),
        title: Text('Appointment Booking', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDate,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return _selectedDate != null && isSameDay(_selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (selectedDay.isBefore(DateTime.now())) return;
              setState(() {
                _selectedDate = selectedDay;
                _focusedDate = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                DateTime normalizedDate = DateTime(date.year, date.month, date.day);
                if (availableAppointments.containsKey(normalizedDate)) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 20),
          Text('Available Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : (_selectedDate == null ||
                availableAppointments[DateTime(
                    _selectedDate!.year, _selectedDate!.month, _selectedDate!.day)] ==
                    null)
                ? Center(child: Text('No appointments available for this date.'))
                : ListView.builder(
              itemCount: availableAppointments[DateTime(
                  _selectedDate!.year, _selectedDate!.month, _selectedDate!.day)]
                  ?.length ??
                  0,
              itemBuilder: (context, index) {
                DateTime normalizedDate = DateTime(
                    _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
                Appointment appointment = availableAppointments[normalizedDate]![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text(
                        appointment.time,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _bookAppointment(appointment);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF078798),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('Book', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'home_page.dart';
//
// class Appointment {
//   final String time;
//
//   Appointment({required this.time});
// }
//
// class CalendarPage extends StatefulWidget {
//   @override
//   _CalendarPageState createState() => _CalendarPageState();
// }
//
// class _CalendarPageState extends State<CalendarPage> {
//   DateTime _focusedDate = DateTime.now();
//   DateTime? _selectedDate;
//   Map<DateTime, List<Appointment>> availableAppointments = {};
//
//   @override
//   void initState() {
//     super.initState();
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
//             tempAppointments[normalizedDate]!.add(Appointment(time: time));
//           } catch (e) {
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
//
//     print("Available slots: $availableAppointments");
//   }
//
//   Future<void> _bookAppointment(Appointment appointment) async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null || _selectedDate == null) return;
//
//     // Ensure the date format is "YYYY-M-D" (matching Firestore)
//     String formattedDate =
//         "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}";  // This gives "2025-4-5"
//
//     try {
//       // Add appointment to the user's appointments collection
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('appointments')
//           .add({
//         'date': formattedDate, // Ensures YYYY-M-D format
//         'time': appointment.time,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       // Get the assigned doctor's ID
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//
//       String assignedDoctorId = userDoc['assignedDoctorId'];
//
//       // Find the slot in the doctor's collection
//       QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(assignedDoctorId)
//           .collection('slots')
//           .where('date', isEqualTo: formattedDate) // Ensure YYYY-M-D format
//           .where('time', isEqualTo: appointment.time) // Time should match exactly
//           .get();
//
//       // If the slot is found, remove it
//       if (slotSnapshot.docs.isNotEmpty) {
//         for (var doc in slotSnapshot.docs) {
//           await doc.reference.delete();
//           print("Slot removed from doctor's available slots.");
//         }
//       } else {
//         print("No matching slot found for doctor.");
//       }
//
//       // Fetch available slots again to update the UI
//       _fetchAvailableSlots();
//
//       // Close the booking screen and show confirmation
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Appointment booked for ${appointment.time}'),
//           backgroundColor: Color(0xFF078798),
//         ),
//       );
//     } catch (e) {
//       // Show error message if appointment booking fails
//       print("Error booking appointment: $e"); // More detailed error logs
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to book appointment: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => HomePage()),
//             );
//           },
//           icon: Icon(Icons.home_filled),
//           color: Colors.white,
//         ),
//         backgroundColor: const Color(0xFF078798),
//         title: Text('Appointment Booking', style: TextStyle(color: Colors.white)),
//       ),
//       body: Column(
//         children: [
//           TableCalendar(
//             firstDay: DateTime.utc(2020, 1, 1),
//             lastDay: DateTime.utc(2025, 12, 31),
//             focusedDay: _focusedDate,
//             calendarFormat: CalendarFormat.month,
//             selectedDayPredicate: (day) {
//               return _selectedDate != null && isSameDay(_selectedDate, day);
//             },
//             onDaySelected: (selectedDay, focusedDay) {
//               setState(() {
//                 _selectedDate = selectedDay;
//                 _focusedDate = focusedDay;
//               });
//             },
//             calendarBuilders: CalendarBuilders(
//               markerBuilder: (context, date, events) {
//                 DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//                 if (availableAppointments.containsKey(normalizedDate)) {
//                   return Positioned(
//                     bottom: 1,
//                     child: Container(
//                       width: 5,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   );
//                 }
//                 return null;
//               },
//             ),
//           ),
//           SizedBox(height: 20),
//           Text('Available Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           Expanded(
//             child: _selectedDate == null ||
//                 availableAppointments[DateTime(
//                     _selectedDate!.year, _selectedDate!.month, _selectedDate!.day)] == null
//                 ? Center(child: Text('No appointments available for this date.'))
//                 : ListView.builder(
//               itemCount: availableAppointments[DateTime(
//                   _selectedDate!.year, _selectedDate!.month, _selectedDate!.day)]?.length ?? 0,
//               itemBuilder: (context, index) {
//                 DateTime normalizedDate = DateTime(
//                     _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
//                 Appointment appointment = availableAppointments[normalizedDate]![index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                   child: Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12.0),
//                     ),
//                     elevation: 5,
//                     child: ListTile(
//                       contentPadding: EdgeInsets.all(16.0),
//                       title: Text(
//                         appointment.time,
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                       ),
//                       trailing: ElevatedButton(
//                         onPressed: () {
//                           _bookAppointment(appointment);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color(0xFF078798),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                         ),
//                         child: Text('Book', style: TextStyle(color: Colors.white)),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//


/// random
// Future<void> _bookAppointment(Appointment appointment) async {
//   User? user = FirebaseAuth.instance.currentUser;
//   if (user == null || _selectedDate == null) return;
//
//   // Ensure YYYY-MM-DD format
//   String formattedDate =
//       "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
//
//   try {
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('appointments')
//         .add({
//       'date': formattedDate, // Ensures YYYY-MM-DD format
//       'time': appointment.time,
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//
//     DocumentSnapshot userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .get();
//
//     String assignedDoctorId = userDoc['assignedDoctorId'];
//
//     QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(assignedDoctorId)
//         .collection('slots')
//         .where('date', isEqualTo: formattedDate) // YYYY-MM-DD format
//         .where('time', isEqualTo: appointment.time)
//         .get();
//
//     for (var doc in slotSnapshot.docs) {
//       await doc.reference.delete();
//     }
//
//     _fetchAvailableSlots();
//
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Appointment booked for ${appointment.time}'),
//         backgroundColor: Color(0xFF078798),
//       ),
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to book appointment: $e')),
//     );
//   }
// }

/// marking
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
// import 'home_page.dart';
//
// class Appointment {
//   final String time;
//
//   Appointment({required this.time});
// }
//
// class CalendarPage extends StatefulWidget {
//   @override
//   _CalendarPageState createState() => _CalendarPageState();
// }
//
// class _CalendarPageState extends State<CalendarPage> {
//   DateTime _focusedDate = DateTime.now();
//   DateTime? _selectedDate;
//   Map<DateTime, List<Appointment>> availableAppointments = {};
//
//   @override
//   void initState() {
//     super.initState();
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
//             tempAppointments[normalizedDate]!.add(Appointment(time: time));
//           } catch (e) {
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
//
//     print("Available slots: $availableAppointments");
//   }
//
//   Future<void> _bookAppointment(Appointment appointment) async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null || _selectedDate == null) return;
//
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('appointments')
//           .add({
//         'date': "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}",
//         'time': appointment.time,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//
//       String assignedDoctorId = userDoc['assignedDoctorId'];
//
//       QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(assignedDoctorId)
//           .collection('slots')
//           .where('date', isEqualTo: "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}")
//           .where('time', isEqualTo: appointment.time)
//           .get();
//
//       for (var doc in slotSnapshot.docs) {
//         await doc.reference.delete();
//       }
//
//       _fetchAvailableSlots();
//
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Appointment booked for ${appointment.time}'),
//           backgroundColor: Color(0xFF078798),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to book appointment: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => HomePage()),
//             );
//           },
//           icon: Icon(Icons.home_filled),
//           color: Colors.white,
//         ),
//         backgroundColor: const Color(0xFF078798),
//         title: Text('Appointment Booking', style: TextStyle(color: Colors.white)),
//       ),
//       body: Column(
//         children: [
//           TableCalendar(
//             firstDay: DateTime.utc(2020, 1, 1),
//             lastDay: DateTime.utc(2025, 12, 31),
//             focusedDay: _focusedDate,
//             calendarFormat: CalendarFormat.month,
//             selectedDayPredicate: (day) {
//               return _selectedDate != null && isSameDay(_selectedDate, day);
//             },
//             onDaySelected: (selectedDay, focusedDay) {
//               setState(() {
//                 _selectedDate = selectedDay;
//                 _focusedDate = focusedDay;
//               });
//             },
//             calendarBuilders: CalendarBuilders(
//               markerBuilder: (context, date, events) {
//                 DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//                 if (availableAppointments.containsKey(normalizedDate)) {
//                   return Positioned(
//                     bottom: 1,
//                     child: Container(
//                       width: 5,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   );
//                 }
//                 return null;
//               },
//             ),
//           ),
//           SizedBox(height: 20),
//           Text('Available Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           Expanded(
//             child: _selectedDate == null || availableAppointments[_selectedDate] == null
//                 ? Center(child: Text('No appointments available for this date.'))
//                 : ListView.builder(
//               itemCount: availableAppointments[_selectedDate]!.length,
//               itemBuilder: (context, index) {
//                 Appointment appointment = availableAppointments[_selectedDate]![index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                   child: Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12.0),
//                     ),
//                     elevation: 5,
//                     child: ListTile(
//                       contentPadding: EdgeInsets.all(16.0),
//                       title: Text(
//                         appointment.time,
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                       ),
//                       trailing: ElevatedButton(
//                         onPressed: () {
//                           _bookAppointment(appointment);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color(0xFF078798),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                         ),
//                         child: Text('Book', style: TextStyle(color: Colors.white)),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
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
// import 'home_page.dart';
//
// class Appointment {
//   final String time;
//
//   Appointment({required this.time});
// }
//
// class CalendarPage extends StatefulWidget {
//   @override
//   _CalendarPageState createState() => _CalendarPageState();
// }
//
// class _CalendarPageState extends State<CalendarPage> {
//   DateTime _focusedDate = DateTime.now();
//   DateTime? _selectedDate;
//
//   Map<DateTime, List<Appointment>> availableAppointments = {
//     DateTime(2025, 3, 9): [
//       Appointment(time: '1:00 PM - 2:30 PM'),
//       Appointment(time: '3:00 PM - 4:00 PM'),
//     ],
//     DateTime(2025, 2, 15): [
//       Appointment(time: '11:00 AM - 12:00 PM'),
//       Appointment(time: '2:00 PM - 3:00 PM'),
//     ],
//     DateTime(2025, 2, 24): [
//       Appointment(time: '9:00 AM - 10:00 AM'),
//       Appointment(time: '1:30 PM - 2:30 PM'),
//     ],
//   };
//
//   List<Appointment> _getAppointmentsForSelectedDate() {
//     return availableAppointments.entries
//         .where((entry) => isSameDay(entry.key, _selectedDate))
//         .expand((entry) => entry.value)
//         .toList();
//   }
//
//   Future<void> _bookAppointment(Appointment appointment) async {
//     User? user = FirebaseAuth.instance.currentUser;
//
//     if (user != null && _selectedDate != null) {
//       try {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .collection('appointments')
//             .add({
//           'date': _selectedDate!.toIso8601String(),
//           'time': appointment.time,
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Appointment booked for ${appointment.time}'),
//             backgroundColor: Color(0xFF078798),
//           ),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to book appointment: $e')),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please sign in to book an appointment.')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => HomePage()),
//             );
//           },
//           icon: Icon(Icons.home_filled),
//           color: Colors.white,
//         ),
//         backgroundColor: const Color(0xFF078798),
//         title: Text('Appointment Booking', style: TextStyle(color: Colors.white)),
//       ),
//       body: Column(
//         children: [
//           TableCalendar(
//             firstDay: DateTime.utc(2020, 1, 1),
//             lastDay: DateTime.utc(2025, 12, 31),
//             focusedDay: _focusedDate,
//             calendarFormat: CalendarFormat.month,
//             selectedDayPredicate: (day) {
//               return _selectedDate != null && isSameDay(_selectedDate, day);
//             },
//             onDaySelected: (selectedDay, focusedDay) {
//               setState(() {
//                 _selectedDate = selectedDay;
//                 _focusedDate = focusedDay;
//               });
//             },
//             calendarBuilders: CalendarBuilders(
//               markerBuilder: (context, date, events) {
//                 if (availableAppointments.containsKey(date)) {
//                   return Positioned(
//                     bottom: 1,
//                     child: Container(
//                       width: 5,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   );
//                 }
//                 return null;
//               },
//             ),
//           ),
//           SizedBox(height: 20),
//           Text('Available Appointments:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           Expanded(
//             child: _getAppointmentsForSelectedDate().isEmpty
//                 ? Center(child: Text('No appointments available for this date.'))
//                 : ListView.builder(
//               itemCount: _getAppointmentsForSelectedDate().length,
//               itemBuilder: (context, index) {
//                 Appointment appointment = _getAppointmentsForSelectedDate()[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                   child: Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12.0),
//                     ),
//                     elevation: 5,
//                     child: ListTile(
//                       contentPadding: EdgeInsets.all(16.0),
//                       title: Text(
//                         appointment.time,
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                       ),
//                       trailing: ElevatedButton(
//                         onPressed: () {
//                           _bookAppointment(appointment);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color(0xFF078798),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                         ),
//                         child: Text('Book', style: TextStyle(color: Colors.white)),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//

/// ajfdbaskjdas
// import 'package:app/pages/home_page.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class Appointment {
//   final String time;
//
//   Appointment({required this.time});
// }
//
// class CalendarPage extends StatefulWidget {
//   @override
//   _CalendarPageState createState() => _CalendarPageState();
// }
//
// class _CalendarPageState extends State<CalendarPage> {
//   DateTime _focusedDate = DateTime.now();
//   DateTime? _selectedDate;
//
//   Map<DateTime, List<Appointment>> availableAppointments = {
//     DateTime(2025, 3, 9): [
//       Appointment(time: '1:00 PM - 2:30 PM'),
//       Appointment(time: '3:00 PM - 4:00 PM'),
//     ],
//     DateTime(2025, 2, 15): [
//       Appointment(time: '11:00 AM - 12:00 PM'),
//       Appointment(time: '2:00 PM - 3:00 PM'),
//     ],
//     DateTime(2025, 2, 24): [
//       Appointment(time: '9:00 AM - 10:00 AM'),
//       Appointment(time: '1:30 PM - 2:30 PM'),
//     ],
//   };
//
//   List<Appointment> _getAppointmentsForSelectedDate() {
//     return availableAppointments.entries
//         .where((entry) => isSameDay(entry.key, _selectedDate))
//         .expand((entry) => entry.value)
//         .toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(onPressed: (){
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => HomePage()),
//           );
//         }, icon: Icon(Icons.home_filled),color: Colors.white,),
//         backgroundColor: const Color(0xFF078798),
//         title: Text('Appointment Booking', style: TextStyle(color: Colors.white)),
//       ),
//       body: Column(
//         children: [
//           TableCalendar(
//             firstDay: DateTime.utc(2020, 1, 1),
//             lastDay: DateTime.utc(2025, 12, 31),
//             focusedDay: _focusedDate,
//             calendarFormat: CalendarFormat.month,
//             selectedDayPredicate: (day) {
//               return _selectedDate != null && isSameDay(_selectedDate, day);
//             },
//             onDaySelected: (selectedDay, focusedDay) {
//               setState(() {
//                 _selectedDate = selectedDay;
//                 _focusedDate = focusedDay;
//               });
//             },
//             calendarBuilders: CalendarBuilders(
//               markerBuilder: (context, date, events) {
//                 if (availableAppointments.containsKey(date)) {
//                   return Positioned(
//                     bottom: 1,
//                     child: Container(
//                       width: 5,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   );
//                 }
//                 return null;
//               },
//             ),
//           ),
//           SizedBox(height: 20),
//           Text('Available Appointments:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//           Expanded(
//             child: _getAppointmentsForSelectedDate().isEmpty
//                 ? Center(child: Text('No appointments available for this date.'))
//                 : ListView.builder(
//               itemCount: _getAppointmentsForSelectedDate().length,
//               itemBuilder: (context, index) {
//                 Appointment appointment = _getAppointmentsForSelectedDate()[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                   child: Card(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12.0),
//                     ),
//                     elevation: 5,
//                     child: ListTile(
//                       contentPadding: EdgeInsets.all(16.0),
//                       title: Text(
//                         appointment.time,
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                       ),
//                       trailing: ElevatedButton(
//                         onPressed: () {
//                           _bookAppointment(appointment);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color(0xFF078798),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8.0),
//                           ),
//                         ),
//                         child: Text('Book', style: TextStyle(color: Colors.white)),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _bookAppointment(Appointment appointment) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Confirm Booking'),
//         content: Text('Book appointment at ${appointment.time}?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Appointment booked for ${appointment.time}'),
//                   backgroundColor: Color(0xFF078798),
//                 ),
//               );
//             },
//             child: Text('Confirm'),
//           ),
//         ],
//       ),
//     );
//   }
// }
