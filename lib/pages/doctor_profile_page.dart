import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DoctorProfilePage extends StatefulWidget {
  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _clinicPhoneController = TextEditingController();
  final TextEditingController _clinicTelephoneController = TextEditingController();
  final TextEditingController _clinicAddressController = TextEditingController();

  String _gender = 'Female';
  String? _userId;
  String? _profilePicUrl;

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
              _firstNameController.text = data['firstName'] ?? '';
              _lastNameController.text = data['lastName'] ?? '';
              _contactNumberController.text = data['contactNumber'] ?? '';
              _clinicPhoneController.text = data['clinicPhone'] ?? '';
              _clinicTelephoneController.text = data['clinicTelephone'] ?? '';
              _clinicAddressController.text = data['clinicAddress'] ?? '';
              _gender = data['gender'] ?? 'Female';
              _profilePicUrl = data['profilePicUrl'] ?? '';
            });
          }
        });
      }
    } catch (e) {
      print('Error checking user logged in: $e');
    }
  }

  Future<void> _updateDoctorProfile() async {
    if (_userId != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_userId).set({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'contactNumber': _contactNumberController.text,
          'clinicPhone': _clinicPhoneController.text,
          'clinicTelephone': _clinicTelephoneController.text,
          'clinicAddress': _clinicAddressController.text,
          'gender': _gender,
          'profilePicUrl': _profilePicUrl ?? '',
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
      } catch (e) {
        print('Error updating doctor profile: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);
      try {
        final ref = FirebaseStorage.instance.ref().child('doctor_profiles/$_userId.jpg');
        await ref.putFile(imageFile);
        String downloadUrl = await ref.getDownloadURL();

        setState(() {
          _profilePicUrl = downloadUrl;
        });

        await FirebaseFirestore.instance.collection('users').doc(_userId).update({'profilePicUrl': downloadUrl});
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  void _resetToDefault() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _contactNumberController.clear();
      _clinicPhoneController.clear();
      _clinicTelephoneController.clear();
      _clinicAddressController.clear();
      _gender = 'Female';
      _profilePicUrl = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile reset to default.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profilePicUrl != null && _profilePicUrl!.isNotEmpty
                          ? NetworkImage(_profilePicUrl!)
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                decoration: InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
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
              SizedBox(height: 16),
              TextFormField(
                controller: _clinicPhoneController,
                decoration: InputDecoration(labelText: 'Clinic Phone', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _clinicTelephoneController,
                decoration: InputDecoration(labelText: 'Clinic Telephone', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _clinicAddressController,
                decoration: InputDecoration(labelText: 'Clinic Address', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _updateDoctorProfile,
                child: Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
