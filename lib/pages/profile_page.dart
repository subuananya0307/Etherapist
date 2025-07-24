import 'package:app/pages/session_notes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import 'appointments_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = '';
  String gender = '';
  int age = 0;
  final List<double> data = [60, 20, 30, 40, 28, 10];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDetails = await _firestore.collection('users').doc(user.uid).get();

      if (userDetails.exists) {
        setState(() {
          userName = userDetails['firstName'] ?? '';
          gender = userDetails['gender'] ?? '';
          age = userDetails['age'] ?? 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF078798),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage("lib/images/avatar.png"),
                  ),
                  SizedBox(height: 10),
                  Text(userName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(gender, style: TextStyle(fontSize: 16, color: Colors.white,)),
                      ),
                      Container(
                        width: 2,
                        height: 20,
                        color: Colors.white,
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('$age years old', style: TextStyle(fontSize: 16, color: Colors.white,)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10,),

            Padding(
              padding: EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [


                    ElevatedButton(
                      onPressed: () {
                        User? user = _auth.currentUser; // Get the current user
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientVisitsScreen(patientId: user.uid),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF078798),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sticky_note_2, color: Colors.black),
                          SizedBox(width: 10),
                          Text('Session Notes',
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10,),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AppPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF078798),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.black),
                          SizedBox(width: 10),
                          Text('Appointments',
                            style: TextStyle(fontSize: 18, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10,),

            Text('This Month',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
            ),

            Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 1,),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_information, size: 40, color: Color(0xFF078798)),
                        SizedBox(height: 8),
                        Text('Meds', style: TextStyle(fontSize: 16, color: Color(0xFF078798)),),
                      ],
                    ),
                    SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 40, color: Color(0xFF078798)),
                        SizedBox(height: 8),
                        Text('Sessions', style: TextStyle(fontSize: 16, color: Color(0xFF078798)),),
                      ],
                    ),
                    SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle_outlined, size: 40, color: Color(0xFF078798)),
                        SizedBox(height: 8),
                        Text('Visits', style: TextStyle(fontSize: 16, color: Color(0xFF078798)),),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10,),

            Text('Online Sessions',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black,),
            ),
            SizedBox(height: 10,),

            Container(
              padding: EdgeInsets.all(20),
              width: double.infinity,
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: 60,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.transparent, width: 0,),
                  ),
                  barGroups: List.generate(data.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data[index],
                          color: Color(0xFF078798),
                          width: 12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return Text('0 min', style: TextStyle(fontSize: 12));
                          } else if (value == 30) {
                            return Text('30 min', style: TextStyle(fontSize: 12));
                          } else if (value == 60) {
                            return Text('60 min', style: TextStyle(fontSize: 12));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt() + 1}', style: TextStyle(fontSize: 12)); // X-axis labels (1, 2, 3, ...)
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:app/pages/calendar.dart';
// // import 'package:app/pages/update.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
//
// import 'appointments_page.dart';
//
// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});
//
//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }
//
// class _ProfilePageState extends State<ProfilePage> {
//   final List<double> data = [60, 20, 30, 40, 28, 10];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//
//             Container(
//               padding: EdgeInsets.all(16.0),
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Color(0xFF078798),
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(50), // Adjust the radius as per your need
//                   bottomRight: Radius.circular(50), // Adjust the radius as per your need
//                 ),
//               ),
//
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Round image
//                   CircleAvatar(
//                     radius: 50, // Size of the circular image
//                     backgroundImage: AssetImage("lib/images/avatar.png"), // Replace with actual image URL
//                   ),
//                   SizedBox(height: 10),
//                   // Name
//                   Text('Radhika',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Text('Female', style: TextStyle(fontSize: 16, color: Colors.white,),
//                         ),
//                       ),
//                       Container(
//                         width: 2, // Width of the space
//                         height: 20, // Height of the white box
//                         color: Colors.white, // Color of the box
//                       ),
//                       Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Text('25 years old', style: TextStyle( fontSize: 16, color: Colors.white,),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                 ],
//               ),
//             ),
//             SizedBox(height: 10,),
//
//             Padding(
//               padding: EdgeInsets.all(8.0),
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     ElevatedButton(
//                       onPressed: () {
//                         // Navigator.push(
//                         //   context,
//                         //   MaterialPageRoute(builder: (context) => CalendarPage2()),
//                         // );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF078798), // Background color
//                         foregroundColor: Colors.black, // Text color
//                         padding: EdgeInsets.all(16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8), // Optional for rounded corners
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.sticky_note_2, color: Colors.black),
//                           SizedBox(width: 10),
//                           Text('Session Summary',
//                             style: TextStyle(fontSize: 18, color: Colors.black),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(width: 10,),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => AppPage()),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF078798), // Background color
//                         foregroundColor: Colors.black, // Text color
//                         padding: EdgeInsets.all(16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8), // Optional for rounded corners
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.calendar_today, color: Colors.black),
//                           SizedBox(width: 10),
//                           Text('Appointments',
//                             style: TextStyle(fontSize: 18, color: Colors.black),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 10,),
//
//             Text('This Month',
//               style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
//             ),
//             // SizedBox(height: 10,),
//
//             Padding(
//               padding: EdgeInsets.all(16.0),
//               child: Container(
//                 height: 100,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.green, width: 1,),
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.medical_information, size: 40, color: Color(0xFF078798)),
//                         SizedBox(height: 8),  // Space between icon and text
//                         Text('Meds', style: TextStyle(fontSize: 16,color: Color(0xFF078798)),),
//                       ],
//                     ),
//                     SizedBox(width: 16), // Space between the icons
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.calendar_month_outlined, size: 40, color: Color(0xFF078798)),
//                         SizedBox(height: 8),
//                         Text('Sessions', style: TextStyle(fontSize: 16,color: Color(0xFF078798)),),
//                       ],
//                     ),
//                     SizedBox(width: 16), // Space between the icons
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.circle_outlined, size: 40, color: Color(0xFF078798)),
//                         SizedBox(height: 8),
//                         Text('Visits', style: TextStyle(fontSize: 16,color: Color(0xFF078798)),),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             )
//
//             ,SizedBox(height: 10,),
//
//             Text('Online Sessions',
//               style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black,),
//             ),
//             SizedBox(height: 10,),
//
//             Container(
//               padding: EdgeInsets.all(20),
//               width: double.infinity,
//               height: 200,
//               child: BarChart(
//                 BarChartData(
//                   alignment: BarChartAlignment.spaceEvenly,
//                   maxY: 60,
//                   gridData: FlGridData(show: false),
//                   borderData: FlBorderData(
//                     show: true,
//                     border: Border.all(color: Colors.transparent, width: 0,),
//                   ),
//                   barGroups: List.generate(data.length, (index) {
//                     return BarChartGroupData(
//                       x: index,
//                       barRods: [
//                         BarChartRodData(
//                           toY: data[index], // Data value
//                           color: Color(0xFF078798), // Bar color
//                           width: 12,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ],
//                     );
//                   }),
//                   titlesData: FlTitlesData(
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         interval: 30,
//                         getTitlesWidget: (value, meta) {
//                           if (value == 0) {
//                             return Text('0 min', style: TextStyle(fontSize: 12));
//                           } else if (value == 30) {
//                             return Text('30 min', style: TextStyle(fontSize: 12));
//                           } else if (value == 60) {
//                             return Text('60 min', style: TextStyle(fontSize: 12));
//                           }
//                           return const Text('');
//                         },
//                       ),
//                     ),
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         getTitlesWidget: (value, meta) {
//                           return Text('${value.toInt() + 1}', style: TextStyle(fontSize: 12)); // X-axis labels (1, 2, 3, ...)
//                         },
//                       ),
//                     ),
//                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide top titles
//                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide right titles
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
