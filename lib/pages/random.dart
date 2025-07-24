// bottomNavigationBar: BottomNavigationBar(
// currentIndex: 2, // Adjust the index based on your navigation
// onTap: (index) {
// // Handle navigation
// },
// selectedItemColor: const Color(0xFF078798),
// unselectedItemColor: const Color(0xFF078798),
// items: const [
// BottomNavigationBarItem(
// icon: Icon(Icons.quiz),
// label: 'Quiz',
// ),
// BottomNavigationBarItem(
// icon: Icon(Icons.play_circle),
// label: 'MindEx',
// ),
// BottomNavigationBarItem(
// icon: Icon(Icons.apps),
// label: 'Profile',
// ),
// BottomNavigationBarItem(
// icon: Icon(Icons.healing),
// label: 'Therapy',
// ),
// BottomNavigationBarItem(
// icon: Icon(Icons.edit),
// label: 'Edit',
// ),
// ],
// ),
//
/// appp
// appBar: AppBar(
// leading: IconButton(
// onPressed: () {
// Navigator.push(
// context,
// MaterialPageRoute(builder: (context) => HomePage()),  // Ensure navigating back to HomePage
// );
// },
// icon: Icon(Icons.home_filled),
// color: Colors.white,
// ),
//
// backgroundColor: const Color(0xFF078798),
// title: Text('Appointment Booking', style: TextStyle(color: Colors.white)),
// ),

/// afasdsa
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class PatientDetails extends StatelessWidget {
//   final String patientId;
//
//   const PatientDetails({Key? key, required this.patientId}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient Details'),
//         backgroundColor: Colors.teal,
//         elevation: 0,
//       ),
//       body: FutureBuilder<DocumentSnapshot>(
//         future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapshot.hasData || !snapshot.data!.exists) {
//             return const Center(child: Text('Patient data not found.'));
//           }
//
//           final patientData = snapshot.data!.data() as Map<String, dynamic>;
//
//           return SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeaderSection(patientData),
//                 const SizedBox(height: 20),
//                 _buildInfoSection(patientData),
//                 const SizedBox(height: 20),
//                 _buildFeedbackSection(context, patientId),
//                 const SizedBox(height: 20),
//                 _buildRecentVisitsSection(context, patientId),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildHeaderSection(Map<String, dynamic> patientData) {
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       color: Colors.teal,
//       child: Row(
//         children: [
//           const CircleAvatar(
//             radius: 40,
//             backgroundImage: AssetImage('assets/images/patient1.jpg'),
//           ),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 patientData['name'] ?? 'Unknown',
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Age: ${patientData['age'] ?? 'N/A'}, ${patientData['gender'] ?? 'N/A'}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.white70,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Occupation: ${patientData['occupation'] ?? 'N/A'}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.white70,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInfoSection(Map<String, dynamic> patientData) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Patient Information',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Divider(),
//             _buildInfoRow('First Name', patientData['firstName'] ?? 'N/A'),
//             _buildInfoRow('Last Name', patientData['lastName'] ?? 'N/A'),
//             _buildInfoRow('Email', patientData['email'] ?? 'N/A'),
//             _buildInfoRow('Contact', patientData['contact'] ?? 'N/A'),
//             _buildInfoRow('Date of Birth', patientData['dob'] ?? 'N/A'),
//             _buildInfoRow('Marital Status', patientData['maritalStatus'] ?? 'N/A'),
//             _buildInfoRow('Previous Medication', patientData['previousMedication'] ?? 'N/A'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//           Text(value),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRecentVisitsSection(BuildContext context, String patientId) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Recent Visits',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Divider(),
//             StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(patientId)
//                   .collection('appointments')
//                   .orderBy('date', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text('No recent visits found.'));
//                 }
//
//                 final visits = snapshot.data!.docs;
//
//                 return ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: visits.length,
//                   itemBuilder: (context, index) {
//                     var visitData = visits[index].data() as Map<String, dynamic>;
//                     return ListTile(
//                       leading: const Icon(Icons.calendar_today, color: Colors.teal),
//                       title: Text(visitData['date'] ?? 'Unknown Date'),
//                       subtitle: Text(visitData['summary'] ?? 'No details available'),
//                       trailing: ElevatedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => ClinicalNotesScreen(),
//                             ),
//                           );
//                         },
//                         child: const Text('View'),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeedbackSection(BuildContext context, String patientId) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Patient Feedback',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const Divider(),
//             StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(patientId)
//                   .collection('feedback')
//                   .orderBy('timestamp', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Text('No feedback available.');
//                 }
//                 return Column(
//                   children: snapshot.data!.docs.map((doc) {
//                     var feedbackData = doc.data() as Map<String, dynamic>;
//                     return ListTile(
//                       title: Text(feedbackData['feedback'] ?? 'No feedback'),
//                       subtitle: Text(feedbackData['timestamp'].toDate().toString()),
//                     );
//                   }).toList(),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
// class ClinicalNotesScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Clinical Notes'),
//         backgroundColor: Colors.teal,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Patient: Rana Ayub',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             const Text('Date: 10/10/24'),
//             const Divider(height: 24),
//             const Text(
//               'Diagnosis: Social Anxiety Disorder',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const Text(
//                 'Subjective: Patient reports significant anxiety (8/10) in social situations, avoiding gatherings due to fear of judgment.'),
//             const SizedBox(height: 16),
//             const Text(
//               'Objective: Appears anxious, minimal eye contact. Logical thought process.',
//             ),
//             const Text(
//               'Assessment: Social Anxiety Disorder, moderate severity. Avoidance behaviors persist.',
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Plan:',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const Text('1. Continue CBT focusing on exposure techniques.'),
//             const Text('2. Consider starting SSRIs.'),
//             const Text('3. Follow up in 4 weeks.'),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: () {
//                 // Action for adding new clinical notes
//               },
//               child: const Text('Add Notes'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//


///fsafdsa
// class DoctorDashboard extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//
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
//                   'Your Patients',
//                   style: TextStyle(
//                     color: Color(0xFF078798),
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 CircleAvatar(
//                   radius: 28,
//                   backgroundColor: Colors.white,
//                   child: Icon(Icons.person, size: 28, color: Color(0xFF078798)),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 20),
//
//             /// Patients & Their Appointments
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('users')
//                     .where('assignedDoctorId', isEqualTo: user?.uid)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(
//                         child: Text('No patients assigned to you.'));
//                   }
//
//                   final patients = snapshot.data!.docs;
//
//                   return ListView.builder(
//                     itemCount: patients.length,
//                     itemBuilder: (context, index) {
//                       var patientData = patients[index].data() as Map<String, dynamic>;
//                       String patientId = patients[index].id;
//
//                       return PatientWithAppointments(
//                         patientId: patientId,
//                         name: patientData['name'] ?? 'Unknown',
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// Widget to fetch & display patient details + their appointments
// class PatientWithAppointments extends StatelessWidget {
//   final String patientId;
//   final String name;
//
//   const PatientWithAppointments({Key? key, required this.patientId, required this.name}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.only(bottom: 15),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Patient Name
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Color(0xFF078798),
//                   child: Icon(Icons.person, color: Colors.white),
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   name,
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 10),
//
//             /// Fetch & Display Appointments
//             StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(patientId)
//                   .collection('appointments')
//                   .orderBy('date', descending: false)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Text(
//                     'No upcoming appointments.',
//                     style: TextStyle(fontSize: 14, color: Colors.grey),
//                   );
//                 }
//
//                 final appointments = snapshot.data!.docs;
//
//                 return Column(
//                   children: appointments.map((appointment) {
//                     var data = appointment.data() as Map<String, dynamic>;
//                     return AppointmentCard(
//                       date: data['date'] ?? 'Unknown',
//                       time: data['time'] ?? 'Unknown',
//                       session: data['session'] ?? 'General',
//                     );
//                   }).toList(),
//                 );
//               },
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
//   final String date;
//   final String time;
//   final String session;
//
//   const AppointmentCard({Key? key, required this.date, required this.time, required this.session}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.only(top: 10),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             blurRadius: 6,
//             spreadRadius: 2,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.calendar_today, color: Color(0xFF078798)),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "$date at $time",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 "Session: $session",
//                 style: TextStyle(fontSize: 14, color: Colors.black54),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }



/// APPOINTMENTS PAGE!!
// class Appointment {
//   final String time;
//   Appointment({required this.time});
// }
//
// class AppointmentsScreen extends StatefulWidget {
//   @override
//   State<AppointmentsScreen> createState() => _AppointmentsScreenState();
// }
//
// class _AppointmentsScreenState extends State<AppointmentsScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String userName = 'Doctor';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserDetails();
//   }
//
//   void _fetchUserDetails() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
//       if (doc.exists) {
//         setState(() {
//           userName = doc['firstName'] ?? 'Doctor';
//         });
//       }
//     }
//   }
//
//
//   DateTime _selectedDate = DateTime.now();
//   DateTime _focusedDate = DateTime.now();
//
//   // Sample appointment data
//   Map<String, List<Appointment>> appointments = {
//     '2025-02-21': [
//       Appointment(time: '9:00 AM - 10:30 AM'),
//       Appointment(time: '1:00 PM - 2:30 PM'),
//     ],
//     '2025-02-25': [
//       Appointment(time: '11:00 AM - 12:00 PM'),
//       Appointment(time: '3:00 PM - 4:00 PM'),
//     ],
//     '2025-02-29': [
//       Appointment(time: '9:00 AM - 10:00 AM'),
//       Appointment(time: '12:00 PM - 1:00 PM'),
//     ],
//   };
//
//   // Get appointments for selected date
//   List<Appointment> _getAppointmentsForSelectedDate() {
//     String formattedDate =
//         '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
//     return appointments[formattedDate] ?? [];
//   }
//
//   void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
//     setState(() {
//       _selectedDate = selectedDay;
//       _focusedDate = focusedDay;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             // Doctor Profile Section
//             Padding(
//               padding: EdgeInsets.all(20.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: <Widget>[
//                   ClipOval(
//                     child: Image.asset(
//                       'lib/images/avatar.png', // Ensure correct image path
//                       width: 70.0,
//                       height: 70.0,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Text(
//                     'Dr. $userName',
//                     style: TextStyle(color: Color(0xFF078798), fontSize: 28, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Calendar Widget
//             Card(
//               margin: EdgeInsets.symmetric(horizontal: 16),
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: TableCalendar(
//                   firstDay: DateTime.utc(2020, 1, 1),
//                   lastDay: DateTime.utc(2025, 12, 31),
//                   focusedDay: _focusedDate,
//                   selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
//                   onDaySelected: _onDaySelected,
//                   calendarFormat: CalendarFormat.month,
//                   headerStyle: HeaderStyle(
//                     formatButtonVisible: false,
//                     titleCentered: true,
//                   ),
//                   calendarBuilders: CalendarBuilders(
//                     markerBuilder: (context, date, events) {
//                       String formattedDate =
//                           '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//                       if (appointments.containsKey(formattedDate)) {
//                         return Positioned(
//                           bottom: 5,
//                           child: Container(
//                             width: 6,
//                             height: 6,
//                             decoration: BoxDecoration(
//                               color: Colors.red,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         );
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//               ),
//             ),
//
//             SizedBox(height: 10),
//
//             // Choose Schedule Header
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Appointments on ${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
//                   style: TextStyle(
//                     color: Color(0xFF078798),
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//
//             // Display Appointments List
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: _getAppointmentsForSelectedDate().isEmpty
//                   ? Center(
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 20),
//                   child: Text(
//                     'No appointments available.',
//                     style: TextStyle(
//                       color: Color(0xFF078798),
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               )
//                   : Column(
//                 children: _getAppointmentsForSelectedDate()
//                     .map((appointment) => AppointmentCard(time: appointment.time))
//                     .toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class AppointmentCard extends StatefulWidget {
//   final String time;
//   const AppointmentCard({required this.time});
//
//   @override
//   _AppointmentCardState createState() => _AppointmentCardState();
// }
//
// class _AppointmentCardState extends State<AppointmentCard> {
//   bool _isSelected = false;
//
//   void _toggleSelection() {
//     setState(() {
//       _isSelected = !_isSelected;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//         side: BorderSide(color: Color(0xFF078798), width: 2),
//       ),
//       color: _isSelected ? Color(0xFF078798) : Color(0xFF078798).withOpacity(0.2),
//       child: ListTile(
//         leading: GestureDetector(
//           onTap: _toggleSelection,
//           child: Icon(
//             _isSelected ? Icons.check_circle : Icons.circle_outlined,
//             color: _isSelected ? Colors.white : Colors.black,
//           ),
//         ),
//         title: Text(
//           'Time: ${widget.time}',
//           style: TextStyle(
//             color: _isSelected ? Colors.white : Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
