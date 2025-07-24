import 'package:app/pages/vr_page.dart';
import 'package:app/pages/vr_page2.dart';
import 'package:app/util/my_button.dart';
import 'package:flutter/material.dart';

class consentPage2 extends StatefulWidget {
  @override
  State<consentPage2> createState() => consentPageState2();
}

class consentPageState2 extends State<consentPage2> {
  bool _isChecked = false; // Checkbox initial state

  void _submitConsent() {
    // Handle consent submission
    if (_isChecked) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WebViewScreen2()), // NextPage() is the target screen
      );
    } else {
      // Show an alert or a message that the user needs to agree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You need to agree to the terms"),
        ),
      );
    }
  }

  void _cancel() {
    // Go back to the previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding around the content
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),
              Text(
                'Consent Form',
                style: TextStyle(
                  color: Color(0xFF06013F ),
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
        
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '1) I agree that my medical records on eTherapist can be kept for further evaluation, analysis, and documentation, and in all of these, my information will be kept private.\n\n'
                        '2) I understand that technical difficulties may occur before or during the eTherapist sessions and my appointment cannot be started or ended as intended.\n\n'
                        '3) I accept that the professionals can contact interactive sessions with video calls; however, I am informed that the sessions can be conducted via regular voice communication if the technical requirements such as internet speed cannot be met.',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Inter',
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isChecked, // Checkbox state dynamically controlled by _isChecked
                      onChanged: (bool? value) {
                        setState(() {
                          _isChecked = value ?? false; // Update state when checkbox is clicked
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChecked = !_isChecked; // Toggle checkbox state when text is clicked
                          });
                        },
                        child: Text(
                          'I agree to terms & conditions *.',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Inter',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        
        
              MyButton(
                text: "I consent",
                onPressed: _submitConsent, // Call submit consent function
              ),
              SizedBox(height: 20), // Add space between buttons
              MyButton(
                text: "I do not consent",
                onPressed: _cancel, // Call cancel function
              ),
        
        
            ],
          ),
        ),
      ),
    );
  }
}
