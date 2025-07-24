import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart'; // Add this for file picking
import 'dart:io';

class EditPage extends StatefulWidget {
  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _maritalStatusController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();

  String _gender = 'Female';
  String? _userId;
  String _previousMedication = 'No';
  File? _pdfFile; // Store the picked PDF file

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  Future<void> _checkUserLoggedIn() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userId = user.uid;
        await FirebaseFirestore.instance.collection('users').doc(_userId).get().then((documentSnapshot) {
          if (documentSnapshot.exists) {
            Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
            setState(() {
              _firstNameController.text = data['firstName'];
              _lastNameController.text = data['lastName'];
              _contactController.text = data['contact'];
              _dobController.text = data['dob'];
              _ageController.text = data['age'].toString();
              _maritalStatusController.text = data['maritalStatus'];
              _occupationController.text = data['occupation'];
              _gender = data['gender'];
              _previousMedication = data['previousMedication'];
            });
          }
        });
      }
    } catch (e) {
      print('Error checking user logged in: $e');
    }
  }

  Future<void> _updateUserProfile() async {
    if (_userId != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_userId).update({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'contact': _contactController.text,
          'dob': _dobController.text,
          'age': int.parse(_ageController.text),
          'maritalStatus': _maritalStatusController.text,
          'occupation': _occupationController.text,
          'gender': _gender,
          'previousMedication': _previousMedication,
        });
        if (_previousMedication == 'Yes' && _pdfFile != null) {
          await _uploadPDF(_pdfFile!);
        }
      } catch (e) {
        print('Error updating user profile: $e');
      }
    }
  }

  Future<void> _uploadPDF(File file) async {
    try {
      String fileName = 'pdfs/${DateTime.now().millisecondsSinceEpoch}.pdf';
      await FirebaseStorage.instance.ref(fileName).putFile(file);
      print('PDF uploaded to Firebase Storage: $fileName');
    } catch (e) {
      print('Error uploading PDF: $e');
    }
  }

  Future<void> _selectPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
        _ageController.text = _calculateAge(pickedDate).toString();
      });
    }
  }

  int _calculateAge(DateTime dob) {
    final DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (dob.month > today.month || (dob.month == today.month && dob.day > today.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(  // Use SingleChildScrollView to prevent overflow
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDateOfBirth(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ageController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maritalStatusController,
                decoration: const InputDecoration(
                  labelText: 'Marital Status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _occupationController,
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _gender = newValue!;
                  });
                },
                items: ['Male', 'Female', 'Other'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _previousMedication,
                decoration: const InputDecoration(
                  labelText: 'Previous Medication',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _previousMedication = newValue!;
                    if (_previousMedication == 'No') {
                      _pdfFile = null; // Clear the PDF file if "No" is selected
                    }
                  });
                },
                items: ['Yes', 'No'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              if (_previousMedication == 'Yes') ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selectPDF,
                  child: const Text('Upload PDF'),
                ),
                if (_pdfFile != null) Text('PDF selected: ${_pdfFile!.path.split('/').last}')
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_userId != null) {
                    await _updateUserProfile(); // Update profile with new data
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User profile updated')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
                  }
                },
                child: const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:intl/intl.dart';
// import 'package:file_picker/file_picker.dart'; // Add this for file picking
// import 'dart:io';
//
// class EditPage extends StatefulWidget {
//   @override
//   _EditPageState createState() => _EditPageState();
// }
//
// class _EditPageState extends State<EditPage> {
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();
//   final TextEditingController _contactController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _maritalStatusController = TextEditingController();
//   final TextEditingController _occupationController = TextEditingController();
//
//   String _gender = 'Female';
//   String? _userId;
//   String _previousMedication = 'No';
//   File? _pdfFile; // Store the picked PDF file
//
//   @override
//   void initState() {
//     super.initState();
//     _checkUserLoggedIn();
//   }
//
//   Future<void> _signUpUser() async {
//     final String email = _generateRandomEmail();
//     final String password = _generateSecurePassword();
//
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
//       _userId = userCredential.user?.uid;
//
//       // Store initial user data in Firestore
//       await FirebaseFirestore.instance.collection('users').doc(_userId).set({
//         'firstName': _firstNameController.text,
//         'lastName': _lastNameController.text,
//         'contact': _contactController.text,
//         'dob': _dobController.text,
//         'age': int.parse(_ageController.text),
//         'maritalStatus': _maritalStatusController.text,
//         'occupation': _occupationController.text,
//         'gender': _gender,
//         'previousMedication': _previousMedication,
//       });
//     } catch (e) {
//       print('Error signing up user: $e');
//     }
//   }
//
//   Future<void> _checkUserLoggedIn() async {
//     try {
//       final User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         _userId = user.uid;
//         await FirebaseFirestore.instance.collection('users').doc(_userId).get().then((documentSnapshot) {
//           if (documentSnapshot.exists) {
//             Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
//             setState(() {
//               _firstNameController.text = data['firstName'];
//               _lastNameController.text = data['lastName'];
//               _contactController.text = data['contact'];
//               _dobController.text = data['dob'];
//               _ageController.text = data['age'].toString();
//               _maritalStatusController.text = data['maritalStatus'];
//               _occupationController.text = data['occupation'];
//               _gender = data['gender'];
//               _previousMedication = data['previousMedication'];
//             });
//           }
//         });
//       }
//     } catch (e) {
//       print('Error checking user logged in: $e');
//     }
//   }
//
//   String _generateRandomEmail() {
//     return 'user${DateTime.now().millisecondsSinceEpoch}@email.com';
//   }
//
//   String _generateSecurePassword() {
//     return 'password123';
//   }
//
//   Future<void> _updateUserProfile() async {
//     if (_userId != null) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(_userId).update({
//           'firstName': _firstNameController.text,
//           'lastName': _lastNameController.text,
//           'contact': _contactController.text,
//           'dob': _dobController.text,
//           'age': int.parse(_ageController.text),
//           'maritalStatus': _maritalStatusController.text,
//           'occupation': _occupationController.text,
//           'gender': _gender,
//           'previousMedication': _previousMedication,
//         });
//         if (_previousMedication == 'Yes' && _pdfFile != null) {
//           await _uploadPDF(_pdfFile!);
//         }
//       } catch (e) {
//         print('Error updating user profile: $e');
//       }
//     }
//   }
//
//   Future<void> _uploadPDF(File file) async {
//     try {
//       String fileName = 'pdfs/${DateTime.now().millisecondsSinceEpoch}.pdf';
//       await FirebaseStorage.instance.ref(fileName).putFile(file);
//       print('PDF uploaded to Firebase Storage: $fileName');
//     } catch (e) {
//       print('Error uploading PDF: $e');
//     }
//   }
//
//   Future<void> _selectPDF() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
//
//     if (result != null) {
//       setState(() {
//         _pdfFile = File(result.files.single.path!);
//       });
//     }
//   }
//
//   Future<void> _selectDateOfBirth(BuildContext context) async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//
//     if (pickedDate != null) {
//       setState(() {
//         _dobController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
//         _ageController.text = _calculateAge(pickedDate).toString();
//       });
//     }
//   }
//
//   int _calculateAge(DateTime dob) {
//     final DateTime today = DateTime.now();
//     int age = today.year - dob.year;
//     if (dob.month > today.month || (dob.month == today.month && dob.day > today.day)) {
//       age--;
//     }
//     return age;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(  // Use SingleChildScrollView to prevent overflow
//           child: Column(
//             children: [
//               TextField(
//                 controller: _firstNameController,
//                 decoration: const InputDecoration(
//                   labelText: 'First Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _lastNameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Last Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _contactController,
//                 decoration: const InputDecoration(
//                   labelText: 'Contact',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               GestureDetector(
//                 onTap: () => _selectDateOfBirth(context),
//                 child: AbsorbPointer(
//                   child: TextField(
//                     controller: _dobController,
//                     decoration: const InputDecoration(
//                       labelText: 'Date of Birth',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _ageController,
//                 readOnly: true,
//                 decoration: const InputDecoration(
//                   labelText: 'Age',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _maritalStatusController,
//                 decoration: const InputDecoration(
//                   labelText: 'Marital Status',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _occupationController,
//                 decoration: const InputDecoration(
//                   labelText: 'Occupation',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _gender,
//                 decoration: const InputDecoration(
//                   labelText: 'Gender',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _gender = newValue!;
//                   });
//                 },
//                 items: ['Male', 'Female', 'Other'].map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _previousMedication,
//                 decoration: const InputDecoration(
//                   labelText: 'Previous Medication',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _previousMedication = newValue!;
//                     if (_previousMedication == 'No') {
//                       _pdfFile = null; // Clear the PDF file if "No" is selected
//                     }
//                   });
//                 },
//                 items: ['Yes', 'No'].map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               if (_previousMedication == 'Yes') ...[
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: _selectPDF,
//                   child: const Text('Upload PDF'),
//                 ),
//                 if (_pdfFile != null) Text('PDF selected: ${_pdfFile!.path.split('/').last}')
//               ],
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_userId == null) {
//                     await _signUpUser(); // Create a new user if not already logged in
//                   }
//                   await _updateUserProfile(); // Update profile with new data
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User profile updated')));
//                 },
//                 child: const Text('Update Profile'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

///cadasd
//
//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:intl/intl.dart';
// import 'package:file_picker/file_picker.dart'; // Add this for file picking
// import 'dart:io';
//
// class EditPage extends StatefulWidget {
//   @override
//   _EditPageState createState() => _EditPageState();
// }
//
// class _EditPageState extends State<EditPage> {
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();
//   final TextEditingController _contactController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _maritalStatusController = TextEditingController();
//   final TextEditingController _occupationController = TextEditingController();
//
//   String _gender = 'Female';
//   String? _userId;
//   String _previousMedication = 'No';
//   File? _pdfFile; // Store the picked PDF file
//
//   @override
//   void initState() {
//     super.initState();
//     _checkUserLoggedIn();
//   }
//
//   Future<void> _signUpUser() async {
//     final String email = _generateRandomEmail();
//     final String password = _generateSecurePassword();
//
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
//       _userId = userCredential.user?.uid;
//     } catch (e) {
//       print('Error signing up user: $e');
//     }
//   }
//
//   Future<void> _checkUserLoggedIn() async {
//     try {
//       final User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         _userId = user.uid;
//         await FirebaseFirestore.instance.collection('users').doc(_userId).get().then((documentSnapshot) {
//           if (documentSnapshot.exists) {
//             Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
//             setState(() {
//               _firstNameController.text = data['firstName'];
//               _lastNameController.text = data['lastName'];
//               _contactController.text = data['contact'];
//               _dobController.text = data['dob'];
//               _ageController.text = data['age'].toString();
//               _maritalStatusController.text = data['maritalStatus'];
//               _occupationController.text = data['occupation'];
//               _gender = data['gender'];
//               _previousMedication = data['previousMedication'];
//             });
//           }
//         });
//       }
//     } catch (e) {
//       print('Error checking user logged in: $e');
//     }
//   }
//
//   String _generateRandomEmail() {
//     return 'user${DateTime.now().millisecondsSinceEpoch}@email.com';
//   }
//
//   String _generateSecurePassword() {
//     return 'password123';
//   }
//
//   Future<void> _updateUserProfile() async {
//     if (_userId != null) {
//       try {
//         await FirebaseFirestore.instance.collection('users').doc(_userId).update({
//           'firstName': _firstNameController.text,
//           'lastName': _lastNameController.text,
//           'contact': _contactController.text,
//           'dob': _dobController.text,
//           'age': int.parse(_ageController.text),
//           'maritalStatus': _maritalStatusController.text,
//           'occupation': _occupationController.text,
//           'gender': _gender,
//           'previousMedication': _previousMedication,
//         });
//         if (_previousMedication == 'Yes' && _pdfFile != null) {
//           await _uploadPDF(_pdfFile!);
//         }
//       } catch (e) {
//         print('Error updating user profile: $e');
//       }
//     }
//   }
//
//   Future<void> _uploadPDF(File file) async {
//     try {
//       String fileName = 'pdfs/${DateTime.now().millisecondsSinceEpoch}.pdf';
//       await FirebaseStorage.instance.ref(fileName).putFile(file);
//       print('PDF uploaded to Firebase Storage: $fileName');
//     } catch (e) {
//       print('Error uploading PDF: $e');
//     }
//   }
//
//   Future<void> _selectPDF() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
//
//     if (result != null) {
//       setState(() {
//         _pdfFile = File(result.files.single.path!);
//       });
//     }
//   }
//
//   Future<void> _selectDateOfBirth(BuildContext context) async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//
//     if (pickedDate != null) {
//       setState(() {
//         _dobController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
//         _ageController.text = _calculateAge(pickedDate).toString();
//       });
//     }
//   }
//
//   int _calculateAge(DateTime dob) {
//     final DateTime today = DateTime.now();
//     int age = today.year - dob.year;
//     if (dob.month > today.month || (dob.month == today.month && dob.day > today.day)) {
//       age--;
//     }
//     return age;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(  // Use SingleChildScrollView to prevent overflow
//           child: Column(
//             children: [
//               TextField(
//                 controller: _firstNameController,
//                 decoration: InputDecoration(
//                   labelText: 'First Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: _lastNameController,
//                 decoration: InputDecoration(
//                   labelText: 'Last Name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: _contactController,
//                 decoration: InputDecoration(
//                   labelText: 'Contact',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               GestureDetector(
//                 onTap: () => _selectDateOfBirth(context),
//                 child: AbsorbPointer(
//                   child: TextField(
//                     controller: _dobController,
//                     decoration: InputDecoration(
//                       labelText: 'Date of Birth',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: _ageController,
//                 readOnly: true,
//                 decoration: InputDecoration(
//                   labelText: 'Age',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: _maritalStatusController,
//                 decoration: InputDecoration(
//                   labelText: 'Marital Status',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               TextField(
//                 controller: _occupationController,
//                 decoration: InputDecoration(
//                   labelText: 'Occupation',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _gender,
//                 decoration: InputDecoration(
//                   labelText: 'Gender',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _gender = newValue!;
//                   });
//                 },
//                 items: ['Male', 'Female', 'Other'].map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _previousMedication,
//                 decoration: InputDecoration(
//                   labelText: 'Previous Medication',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _previousMedication = newValue!;
//                     if (_previousMedication == 'No') {
//                       _pdfFile = null; // Clear the PDF file if "No" is selected
//                     }
//                   });
//                 },
//                 items: ['Yes', 'No'].map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               if (_previousMedication == 'Yes') ...[
//                 SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: _selectPDF,
//                   child: Text('Upload PDF'),
//                 ),
//                 if (_pdfFile != null) Text('PDF selected: ${_pdfFile!.path.split('/').last}')
//               ],
//               SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _updateUserProfile();
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User profile updated')));
//                 },
//                 child: Text('Update Profile'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }