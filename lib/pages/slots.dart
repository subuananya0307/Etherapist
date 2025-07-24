import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Appointment {
  final String time;

  Appointment({required this.time});
}

class Slots extends StatefulWidget {
  @override
  _SlotsPageState createState() => _SlotsPageState();
}

class _SlotsPageState extends State<Slots> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  Map<DateTime, List<Appointment>> availableAppointments = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailableSlots();
  }

  // Fetch available slots from the Firestore database
  Future<void> _fetchAvailableSlots() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('slots')
        .get();

    if (slotSnapshot.docs.isEmpty) {
      print("No slots found for user: ${user.uid}");
    }

    Map<DateTime, List<Appointment>> tempAppointments = {};

    // Process each slot from Firestore
    for (var doc in slotSnapshot.docs) {
      if (doc.data() is Map<String, dynamic>) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('date') && data.containsKey('time')) {
          String dateString = data['date'];  // Format: "YYYY-MM-DD"
          String timeString = data['time'];  // Format: "HH:mm"

          // Parse the date string into a DateTime object
          List<String> dateParts = dateString.split('-');
          if (dateParts.length == 3) {
            int year = int.parse(dateParts[0]);
            int month = int.parse(dateParts[1]);
            int day = int.parse(dateParts[2]);
            DateTime date = DateTime(year, month, day);

            // Normalize the date to remove time
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);

            // Add the time to the appointment list
            if (!tempAppointments.containsKey(normalizedDate)) {
              tempAppointments[normalizedDate] = [];
            }

            // Add the appointment with the time
            tempAppointments[normalizedDate]!.add(Appointment(time: timeString));
          }
        } else {
          print("Invalid slot document: $doc");
        }
      }
    }

    setState(() {
      availableAppointments = tempAppointments;
    });

    print("Available slots: $availableAppointments");
  }

  // Add a new slot to the Firestore database
  void _addSlot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    // Show the date picker
    await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    ).then((date) async {
      if (date != null) {
        selectedDate = date;

        // Show the time picker
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

    // If both date and time are selected, proceed
    if (selectedDate != null && selectedTime != null) {
      // Format the selected date as a string "YYYY-MM-DD"
      String formattedDate = "${selectedDate?.year}-${selectedDate?.month}-${selectedDate?.day}";

      // Format the selected time as a string "HH:mm"
      String formattedTime = "${selectedTime?.hour}:${selectedTime?.minute}";

      // Save the data in Firestore with formatted date and time
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('slots')
          .add({
        'date': formattedDate,
        'time': formattedTime,
      });

      print("Slot Added: $formattedDate $formattedTime");

      // Fetch available slots again after adding a new slot
      _fetchAvailableSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Available Slots", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF078798),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: _focusedDate,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                // Mark the days that have available slots
                markerBuilder: (context, date, events) {
                  if (availableAppointments.containsKey(date)) {
                    return Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        height: 5,
                        width: 5,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return SizedBox();
                },
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: availableAppointments.isEmpty
                  ? Center(child: Text("No available slots"))
                  : ListView.builder(
                itemCount: availableAppointments.length,
                itemBuilder: (context, index) {
                  DateTime date = availableAppointments.keys.elementAt(index);
                  List<Appointment> appointments = availableAppointments[date]!;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        '${date.month}/${date.day}/${date.year}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: appointments
                            .map((appointment) => Text(appointment.time))
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button to add a new slot
      floatingActionButton: FloatingActionButton(
        onPressed: _addSlot,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: "Add New Slot",
        backgroundColor: Color(0xFF078798),
      ),
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';
//
// class Appointment {
//   final String time;
//
//   Appointment({required this.time});
// }
//
// class Slots extends StatefulWidget {
//   @override
//   _SlotsPageState createState() => _SlotsPageState();
// }
//
// class _SlotsPageState extends State<Slots> {
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
//   // Fetch available slots from the current user's 'slots' collection
//   // Future<void> _fetchAvailableSlots() async {
//   //   User? user = FirebaseAuth.instance.currentUser;
//   //   if (user == null) return;
//   //
//   //   QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
//   //       .collection('users')
//   //       .doc(user.uid)
//   //       .collection('slots')
//   //       .get();
//   //
//   //   if (slotSnapshot.docs.isEmpty) {
//   //     print("No slots found for user: ${user.uid}");
//   //   }
//   //
//   //   Map<DateTime, List<Appointment>> tempAppointments = {};
//   //
//   //   for (var doc in slotSnapshot.docs) {
//   //     if (doc.data() is Map<String, dynamic>) {
//   //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//   //
//   //       if (data.containsKey('timestamp') && data.containsKey('time')) {
//   //         Timestamp timestamp = data['timestamp'];
//   //         String time = data['time'];
//   //
//   //         DateTime date = timestamp.toDate();
//   //         DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//   //
//   //         if (!tempAppointments.containsKey(normalizedDate)) {
//   //           tempAppointments[normalizedDate] = [];
//   //         }
//   //         tempAppointments[normalizedDate]!.add(Appointment(time: time));
//   //       } else {
//   //         print("Invalid slot document: $doc");
//   //       }
//   //     }
//   //   }
//   //
//   //   setState(() {
//   //     availableAppointments = tempAppointments;
//   //   });
//   //
//   //   print("Available slots: $availableAppointments");
//   // }
//   Future<void> _fetchAvailableSlots() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     QuerySnapshot slotSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('slots')
//         .get();
//
//     if (slotSnapshot.docs.isEmpty) {
//       print("No slots found for user: ${user.uid}");
//     }
//
//     Map<DateTime, List<Appointment>> tempAppointments = {};
//
//     for (var doc in slotSnapshot.docs) {
//       if (doc.data() is Map<String, dynamic>) {
//         Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//
//         if (data.containsKey('date') && data.containsKey('time')) {
//           String dateString = data['date'];  // Format: "YYYY-MM-DD"
//           String timeString = data['time'];  // Format: "HH:mm"
//
//           // Parse the date string into a DateTime object
//           List<String> dateParts = dateString.split('-');
//           if (dateParts.length == 3) {
//             int year = int.parse(dateParts[0]);
//             int month = int.parse(dateParts[1]);
//             int day = int.parse(dateParts[2]);
//             DateTime date = DateTime(year, month, day);
//
//             // Normalize the date to remove time
//             DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//
//             // Add the time to the appointment list
//             if (!tempAppointments.containsKey(normalizedDate)) {
//               tempAppointments[normalizedDate] = [];
//             }
//
//             // Add the appointment with the time
//             tempAppointments[normalizedDate]!.add(Appointment(time: timeString));
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
//   /// Add a New Slot for Appointments
//   void _addSlot() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     DateTime? selectedDate;
//     TimeOfDay? selectedTime;
//
//     // Show the date picker
//     await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2030),
//     ).then((date) async {
//       if (date != null) {
//         selectedDate = date;
//
//         // Show the time picker
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
//     // If both date and time are selected, proceed
//     if (selectedDate != null && selectedTime != null) {
//       // Format the selected date as a string "YYYY-MM-DD"
//       String formattedDate = "${selectedDate?.year}-${selectedDate?.month}-${selectedDate?.day}";
//
//       // Format the selected time as a string "HH:mm"
//       String formattedTime = "${selectedTime?.hour}:${selectedTime?.minute}";
//
//       // Save the data in Firestore with formatted date and time
//       FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('slots')
//           .add({
//         'date': formattedDate,
//         'time': formattedTime,
//       });
//
//       print("Slot Added: $formattedDate $formattedTime");
//
//       // Fetch available slots again after adding a new slot
//       _fetchAvailableSlots();
//     }
//   }
//
//   // void _addSlot() async {
//   //   final user = FirebaseAuth.instance.currentUser;
//   //   if (user == null) return;
//   //
//   //   DateTime? selectedDate;
//   //   TimeOfDay? selectedTime;
//   //
//   //   await showDatePicker(
//   //     context: context,
//   //     initialDate: DateTime.now(),
//   //     firstDate: DateTime.now(),
//   //     lastDate: DateTime(2030),
//   //   ).then((date) async {
//   //     if (date != null) {
//   //       selectedDate = date;
//   //       await showTimePicker(
//   //         context: context,
//   //         initialTime: TimeOfDay.now(),
//   //       ).then((time) {
//   //         if (time != null) {
//   //           selectedTime = time;
//   //         }
//   //       });
//   //     }
//   //   });
//   //
//   //   if (selectedDate != null && selectedTime != null) {
//   //     DateTime appointmentDateTime = DateTime(
//   //       selectedDate!.year,
//   //       selectedDate!.month,
//   //       selectedDate!.day,
//   //       selectedTime!.hour,
//   //       selectedTime!.minute,
//   //     );
//   //
//   //     FirebaseFirestore.instance
//   //         .collection('users')
//   //         .doc(user.uid)
//   //         .collection('slots')
//   //         .add({
//   //       'timestamp': Timestamp.fromDate(appointmentDateTime),
//   //       'time': "${selectedTime!.hour}:${selectedTime!.minute}",
//   //     });
//   //
//   //     print("Slot Added: $appointmentDateTime");
//   //
//   //     // Fetch available slots again after adding a new slot
//   //     _fetchAvailableSlots();
//   //   }
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Available Slots", style: TextStyle(color: Colors.white)),
//         backgroundColor: const Color(0xFF078798),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TableCalendar(
//               firstDay: DateTime.utc(2020, 1, 1),
//               lastDay: DateTime.utc(2025, 12, 31),
//               focusedDay: _focusedDate,
//               selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
//               onDaySelected: (selectedDay, focusedDay) {
//                 setState(() {
//                   _selectedDate = selectedDay;
//                 });
//               },
//               calendarBuilders: CalendarBuilders(
//                 // This will mark the days that have available slots
//                 markerBuilder: (context, date, events) {
//                   if (availableAppointments.containsKey(date)) {
//                     return Positioned(
//                       bottom: 1,
//                       right: 1,
//                       child: Container(
//                         height: 5,
//                         width: 5,
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     );
//                   }
//                   return SizedBox();
//                 },
//               ),
//             ),
//             SizedBox(height: 20),
//             Expanded(
//               child: availableAppointments.isEmpty
//                   ? Center(child: Text("No available slots"))
//                   : ListView.builder(
//                 itemCount: availableAppointments.length,
//                 itemBuilder: (context, index) {
//                   DateTime date = availableAppointments.keys.elementAt(index);
//                   List<Appointment> appointments = availableAppointments[date]!;
//
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 8),
//                     child: ListTile(
//                       title: Text(
//                         '${date.month}/${date.day}/${date.year}',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: appointments
//                             .map((appointment) => Text(appointment.time))
//                             .toList(),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       // FloatingActionButton to add a new slot
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addSlot,
//         child: Icon(Icons.add, color: Colors.white),
//         tooltip: "Add New Slot",
//         backgroundColor: Color(0xFF078798),
//       ),
//     );
//   }
// }
