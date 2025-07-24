import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../util/my_button.dart';
import '../util/question_tile.dart';
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final List<Map<String, dynamic>> questions = [
    {"questionText": "Do you feel uncomfortable when attention is on you?", "feature": "fear_attention"},
    {"questionText": "Do you feel anxious while speaking in public?", "feature": "anxious_speaking"},
    {"questionText": "Do you avoid talking to strangers?", "feature": "avoid_strangers"},
    {"questionText": "Do you excessively worry about social situations?", "feature": "excessive_worry"},
    {"questionText": "Do you feel uneasy around people?", "feature": "uncomfortable_around_people"},
    {"questionText": "Do you struggle with self-confidence?", "feature": "under_confidence"},
    {"questionText": "Do you experience physical symptoms (sweating, shaking) in social situations?", "feature": "physical_symptoms"},
    {"questionText": "Do you have trouble sleeping due to social anxiety?", "feature": "sleep_disturbances"},
    {"questionText": "Do you avoid gatherings or group activities?", "feature": "avoid_gatherings"},
    {"questionText": "Do you find it hard to maintain eye contact?", "feature": "avoid_eye_contact"},
  ];

  Map<String, int> responses = {
    "fear_attention": 0,
    "anxious_speaking": 0,
    "avoid_strangers": 0,
    "excessive_worry": 0,
    "uncomfortable_around_people": 0,
    "under_confidence": 0,
    "physical_symptoms": 0,
    "sleep_disturbances": 0,
    "avoid_gatherings": 0,
    "avoid_eye_contact": 0,
  };

  bool isLoading = false;

  Future<void> submitResponses() async {
    setState(() => isLoading = true);
    final Uri url = Uri.parse("https://anxiety-predictor.onrender.com/predict");

    try {
      print('Sending request with payload: ${jsonEncode(responses)}');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(responses),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      print('Parsed Response: $data');

      String anxietyLevel = data["prediction"] ?? "Unknown";
      if (anxietyLevel == "Unknown" || anxietyLevel.isEmpty) {
        _showError("API did not return a valid anxiety level.");
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(anxietyLevel: anxietyLevel),
        ),
      );
    } catch (e) {
      print("Error: $e");
      _showError("Network error. Please try again later.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Anxiety Self Check',
                style: TextStyle(
                  color: Color(0xFF06013F),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Evaluate your social anxiety in minutes.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: QuestionTile(
                      questionText: question["questionText"],
                      options: ["Never (0)", "Rarely (1)", "Sometimes (2)", "Often (3)", "Always (4)"],
                      selectedOptionIndex: responses[question["feature"]],
                      onOptionSelected: (selectedIndex) {
                        setState(() {
                          responses[question["feature"]] = selectedIndex!;
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              MyButton(
                text: isLoading ? "Submitting..." : "Submit",
                onPressed:  submitResponses,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../util/my_button.dart';
// import '../util/question_tile.dart';
// import 'result_page.dart';
//
// class QuizPage extends StatefulWidget {
//   const QuizPage({super.key});
//
//   @override
//   State<QuizPage> createState() => _QuizPageState();
// }
//
// class _QuizPageState extends State<QuizPage> {
//   final List<Map<String, dynamic>> questions = [
//     {"questionText": "Do you feel uncomfortable when attention is on you?", "feature": "fear_attention"},
//     {"questionText": "Do you feel anxious while speaking in public?", "feature": "anxious_speaking"},
//     {"questionText": "Do you avoid talking to strangers?", "feature": "avoid_strangers"},
//     {"questionText": "Do you excessively worry about social situations?", "feature": "excessive_worry"},
//     {"questionText": "Do you feel uneasy around people?", "feature": "uncomfortable_around_people"},
//     {"questionText": "Do you struggle with self-confidence?", "feature": "under_confidence"},
//     {"questionText": "Do you experience physical symptoms (sweating, shaking) in social situations?", "feature": "physical_symptoms"},
//     {"questionText": "Do you have trouble sleeping due to social anxiety?", "feature": "sleep_disturbances"},
//     {"questionText": "Do you avoid gatherings or group activities?", "feature": "avoid_gatherings"},
//     {"questionText": "Do you find it hard to maintain eye contact?", "feature": "avoid_eye_contact"},
//   ];
//
//   Map<String, int> responses = {
//     "fear_attention": 0,
//     "anxious_speaking": 0,
//     "avoid_strangers": 0,
//     "excessive_worry": 0,
//     "uncomfortable_around_people": 0,
//     "under_confidence": 0,
//     "physical_symptoms": 0,
//     "sleep_disturbances": 0,
//     "avoid_gatherings": 0,
//     "avoid_eye_contact": 0,
//   };
//
//   final ScrollController _scrollController = ScrollController();
//
//   Future<void> submitResponses() async {
//     // final Uri url = Uri.parse("http://192.168.0.104:3000/predict");
//     // final Uri url = Uri.parse("http://10.0.2.2:6000/predict");
//     // final Uri url = Uri.parse("http://192.168.0.101:6000/predict");
//
//     final Uri url = Uri.parse("https://anxiety-predictor.onrender.com/predict");
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(responses),
//       );
//
//       // Log the response status code and body
//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         String anxietyLevel = data["anxiety_level"];
//         // Navigate to the result page
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ResultPage(anxietyLevel: anxietyLevel),
//           ),
//         );
//       } else {
//         _showError("Error: Unable to fetch result. Status code: ${response.statusCode}");
//       }
//     } catch (e) {
//       _showError("Error: ${e.toString()}");
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Scrollbar(
//         controller: _scrollController,
//         thumbVisibility: true,
//         thickness: 10.0,
//         radius: const Radius.circular(10),
//         child: SingleChildScrollView(
//           controller: _scrollController,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 const Align(
//                   alignment: Alignment.topLeft,
//                   child: Text(
//                     'Anxiety Self Check',
//                     style: TextStyle(
//                       color: Color(0xFF06013F),
//                       fontFamily: 'Inter',
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const Align(
//                   alignment: Alignment.topLeft,
//                   child: Text(
//                     'Evaluate your social anxiety in minutes.',
//                     style: TextStyle(
//                       color: Color.fromRGBO(0, 0, 0, 1),
//                       fontFamily: 'Tuffy',
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: questions.length,
//                   itemBuilder: (context, index) {
//                     final question = questions[index];
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 5.0),
//                       child: QuestionTile(
//                         questionText: question["questionText"],
//                         options: ["Never (0)", "Rarely (1)", "Sometimes (2)", "Often (3)", "Always (4)"],
//                         selectedOptionIndex: responses[question["feature"]],
//                         onOptionSelected: (selectedIndex) {
//                           setState(() {
//                             responses[question["feature"]] = selectedIndex!;
//                           });
//                         },
//                       ),
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 MyButton(
//                   text: "Submit",
//                   onPressed: submitResponses,
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//



/// local host
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../util/my_button.dart';
// import '../util/question_tile.dart';
// import 'result_page.dart';
//
// class QuizPage extends StatefulWidget {
//   const QuizPage({super.key});
//
//   @override
//   State<QuizPage> createState() => _QuizPageState();
// }
//
// class _QuizPageState extends State<QuizPage> {
//   final List<Map<String, dynamic>> questions = [
//     {"questionText": "Do you feel uncomfortable when attention is on you?", "feature": "fear_attention"},
//     {"questionText": "Do you feel anxious while speaking in public?", "feature": "anxious_speaking"},
//     {"questionText": "Do you avoid talking to strangers?", "feature": "avoid_strangers"},
//     {"questionText": "Do you excessively worry about social situations?", "feature": "excessive_worry"},
//     {"questionText": "Do you feel uneasy around people?", "feature": "uncomfortable_around_people"},
//     {"questionText": "Do you struggle with self-confidence?", "feature": "under_confidence"},
//     {"questionText": "Do you experience physical symptoms (sweating, shaking) in social situations?", "feature": "physical_symptoms"},
//     {"questionText": "Do you have trouble sleeping due to social anxiety?", "feature": "sleep_disturbances"},
//     {"questionText": "Do you avoid gatherings or group activities?", "feature": "avoid_gatherings"},
//     {"questionText": "Do you find it hard to maintain eye contact?", "feature": "avoid_eye_contact"},
//   ];
//
//   Map<String, int> responses = {
//     "fear_attention": 0,
//     "anxious_speaking": 0,
//     "avoid_strangers": 0,
//     "excessive_worry": 0,
//     "uncomfortable_around_people": 0,
//     "under_confidence": 0,
//     "physical_symptoms": 0,
//     "sleep_disturbances": 0,
//     "avoid_gatherings": 0,
//     "avoid_eye_contact": 0,
//   };
//
//   final ScrollController _scrollController = ScrollController();
//
//   Future<void> submitResponses() async {
//     // final Uri url = Uri.parse("http://192.168.0.104:3000/predict");
//     // final Uri url = Uri.parse("http://10.0.2.2:6000/predict");
//     // final Uri url = Uri.parse("http://192.168.0.101:6000/predict");
//
//     final Uri url = Uri.parse("http://192.168.248.254:6000/predict");
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(responses),
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         String anxietyLevel = data["anxiety_level"];
//         // Navigate to the result page
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ResultPage(anxietyLevel: anxietyLevel),
//           ),
//         );
//       } else {
//         _showError("Error: Unable to fetch result");
//       }
//     } catch (e) {
//       _showError("Error: ${e.toString()}");
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Scrollbar(
//         controller: _scrollController,
//         thumbVisibility: true,
//         thickness: 10.0,
//         radius: const Radius.circular(10),
//         child: SingleChildScrollView(
//           controller: _scrollController,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 const Align(
//                   alignment: Alignment.topLeft,
//                   child: Text(
//                     'Anxiety Self Check',
//                     style: TextStyle(
//                       color: Color(0xFF06013F),
//                       fontFamily: 'Inter',
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const Align(
//                   alignment: Alignment.topLeft,
//                   child: Text(
//                     'Evaluate your social anxiety in minutes.',
//                     style: TextStyle(
//                       color: Color.fromRGBO(0, 0, 0, 1),
//                       fontFamily: 'Tuffy',
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: questions.length,
//                   itemBuilder: (context, index) {
//                     final question = questions[index];
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 5.0),
//                       child: QuestionTile(
//                         questionText: question["questionText"],
//                         options: ["Never (0)", "Rarely (1)", "Sometimes (2)", "Often (3)", "Always (4)"],
//                         selectedOptionIndex: responses[question["feature"]],
//                         onOptionSelected: (selectedIndex) {
//                           setState(() {
//                             responses[question["feature"]] = selectedIndex!;
//                           });
//                         },
//                       ),
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 MyButton(
//                   text: "Submit",
//                   onPressed: submitResponses,
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//


/// idk
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../util/question_tile.dart';
//
// class QuizPage extends StatefulWidget {
//   const QuizPage({super.key});
//
//   @override
//   State<QuizPage> createState() => _QuizPageState();
// }
//
// class _QuizPageState extends State<QuizPage> {
//   final List<Map<String, dynamic>> questions = [
//     {"questionText": "Do you feel uncomfortable when attention is on you?", "feature": "fear_attention"},
//     {"questionText": "Do you feel anxious while speaking in public?", "feature": "anxious_speaking"},
//     {"questionText": "Do you avoid talking to strangers?", "feature": "avoid_strangers"},
//     {"questionText": "Do you excessively worry about social situations?", "feature": "excessive_worry"},
//     {"questionText": "Do you feel uneasy around people?", "feature": "uncomfortable_around_people"},
//     {"questionText": "Do you struggle with self-confidence?", "feature": "under_confidence"},
//     {"questionText": "Do you experience physical symptoms (sweating, shaking) in social situations?", "feature": "physical_symptoms"},
//     {"questionText": "Do you have trouble sleeping due to social anxiety?", "feature": "sleep_disturbances"},
//     {"questionText": "Do you avoid gatherings or group activities?", "feature": "avoid_gatherings"},
//     {"questionText": "Do you find it hard to maintain eye contact?", "feature": "avoid_eye_contact"},
//   ];
//
//   Map<String, int> responses = {
//     "fear_attention": 0,
//     "anxious_speaking": 0,
//     "avoid_strangers": 0,
//     "excessive_worry": 0,
//     "uncomfortable_around_people": 0,
//     "under_confidence": 0,
//     "physical_symptoms": 0,
//     "sleep_disturbances": 0,
//     "avoid_gatherings": 0,
//     "avoid_eye_contact": 0,
//   };
//
//   String? predictionResult;
//
//   Future<void> submitResponses() async {
//     final Uri url = Uri.parse("http://192.168.0.104:6000/predict");
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(responses),
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           predictionResult = data["anxiety_level"];
//         });
//       } else {
//         setState(() {
//           predictionResult = "Error: Unable to fetch result";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         predictionResult = "Error: ${e.toString()}";
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final ScrollController scrollController = ScrollController();
//
//     return Scaffold(
//       backgroundColor: Colors.grey[200],
//       body: Scrollbar(
//         thumbVisibility: true, // Always visible
//         controller: scrollController,
//         thickness: 10.0,
//         radius: const Radius.circular(10),
//         child: SingleChildScrollView(
//           controller: scrollController,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 const Align(
//                   alignment: Alignment.topLeft,
//                   child: Text(
//                     'Anxiety Self Check',
//                     style: TextStyle(
//                       color: Color(0xFF06013F),
//                       fontFamily: 'Inter',
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const Align(
//                   alignment: Alignment.topLeft,
//                   child: Text(
//                     'Evaluate your social anxiety in minutes.',
//                     style: TextStyle(
//                       color: Color.fromRGBO(0, 0, 0, 1),
//                       fontFamily: 'Tuffy',
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: questions.length,
//                   itemBuilder: (context, index) {
//                     final question = questions[index];
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 5.0),
//                       child: QuestionTile(
//                         questionText: question["questionText"],
//                         options: ["Never (0)", "Rarely (1)", "Sometimes (2)", "Often (3)", "Always (4)"],
//                         selectedOptionIndex: responses[question["feature"]],
//                         onOptionSelected: (selectedIndex) {
//                           setState(() {
//                             responses[question["feature"]] = selectedIndex!;
//                           });
//                         },
//                       ),
//                     );
//                   },
//                 ),
//                 ElevatedButton(
//                   onPressed: submitResponses,
//                   child: const Text("Submit"),
//                 ),
//                 if (predictionResult != null)
//                   Padding(
//                     padding: const EdgeInsets.all(10.0),
//                     child: Text(
//                       "Anxiety Level: $predictionResult",
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.red,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../util/question_tile.dart';
//
// class QuizPage extends StatefulWidget {
//   const QuizPage({super.key});
//
//   @override
//   State<QuizPage> createState() => _QuizPageState();
// }
//
// class _QuizPageState extends State<QuizPage> {
//   // List of questions linked to model features
//   final List<Map<String, dynamic>> questions = [
//     {"questionText": "Do you feel uncomfortable when attention is on you?", "feature": "fear_attention"},
//     {"questionText": "Do you feel anxious while speaking in public?", "feature": "anxious_speaking"},
//     {"questionText": "Do you avoid talking to strangers?", "feature": "avoid_strangers"},
//     {"questionText": "Do you excessively worry about social situations?", "feature": "excessive_worry"},
//     {"questionText": "Do you feel uneasy around people?", "feature": "uncomfortable_around_people"},
//     {"questionText": "Do you struggle with self-confidence?", "feature": "under_confidence"},
//     {"questionText": "Do you experience physical symptoms (sweating, shaking) in social situations?", "feature": "physical_symptoms"},
//     {"questionText": "Do you have trouble sleeping due to social anxiety?", "feature": "sleep_disturbances"},
//     {"questionText": "Do you avoid gatherings or group activities?", "feature": "avoid_gatherings"},
//     {"questionText": "Do you find it hard to maintain eye contact?", "feature": "avoid_eye_contact"},
//   ];
//
//   // User responses (default to 0)
//   Map<String, int> responses = {
//     "fear_attention": 0,
//     "anxious_speaking": 0,
//     "avoid_strangers": 0,
//     "excessive_worry": 0,
//     "uncomfortable_around_people": 0,
//     "under_confidence": 0,
//     "physical_symptoms": 0,
//     "sleep_disturbances": 0,
//     "avoid_gatherings": 0,
//     "avoid_eye_contact": 0,
//   };
//
//   String? predictionResult; // Stores anxiety level result
//
//   // Function to send data to model and get prediction
//   Future<void> submitResponses() async {
//     final Uri url = Uri.parse("http://192.168.0.104:6000/predict"); // Change URL as needed
//
//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(responses),
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           predictionResult = data["anxiety_level"];
//         });
//       } else {
//         setState(() {
//           predictionResult = "Error: Unable to fetch result";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         predictionResult = "Error: ${e.toString()}";
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[200],
//       appBar: AppBar(
//         title: const Text("Anxiety Self-Check"),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 10.0),
//               child: Text(
//                 "Evaluate your social anxiety in minutes.",
//                 style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: questions.length,
//                 itemBuilder: (context, index) {
//                   final question = questions[index];
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 5.0),
//                     child: QuestionTile(
//                       questionText: question["questionText"],
//                       options: ["Never (0)", "Rarely (1)", "Sometimes (2)", "Often (3)", "Always (4)"],
//                       selectedOptionIndex: responses[question["feature"]],
//                       onOptionSelected: (selectedIndex) {
//                         setState(() {
//                           responses[question["feature"]] = selectedIndex!;
//                         });
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ),
//             ElevatedButton(
//               onPressed: submitResponses,
//               child: const Text("Submit"),
//             ),
//             if (predictionResult != null)
//               Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Text(
//                   "Anxiety Level: $predictionResult",
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:app/util/question_tile.dart';
//
// import '../util/my_button.dart';
//
// class QuizPage extends StatefulWidget {
//   const QuizPage({super.key});
//
//   @override
//   State<QuizPage> createState() => _QuizPageState();
// }
//
// class _QuizPageState extends State<QuizPage> {
//   // List of questions and options
//   final List<Map<String, dynamic>> questions = [
//     {
//       "questionText": "What is the capital of France?",
//       "options": ["Berlin", "Madrid", "Paris", "Rome"],
//       "correctAnswerIndex": 2
//     },
//     {
//       "questionText": "What is the capital of Spain?",
//       "options": ["Berlin", "Madrid", "Paris", "Rome"],
//       "correctAnswerIndex": 1
//     },
//     {
//       "questionText": "What is the capital of Italy?",
//       "options": ["Berlin", "Madrid", "Paris", "Rome"],
//       "correctAnswerIndex": 3
//     },
//     {
//       "questionText": "What is the capital of Germany?",
//       "options": ["Berlin", "Madrid", "Paris", "Rome"],
//       "correctAnswerIndex": 0
//     },
//     {
//       "questionText": "What is the capital of Japan?",
//       "options": ["Berlin", "Tokyo", "Paris", "Rome"],
//       "correctAnswerIndex": 1
//     },
//   ];
//
//   // To track selected answers for each question
//   List<int?> selectedAnswers = List.filled(10, null); // Default null for no selection
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//
//       body: Scrollbar(
//         thumbVisibility: true,
//         thickness: 10.0,
//         radius: Radius.circular(10),
//
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: Text(
//                     'Anxiety Self Check',
//                     style: TextStyle(
//                       color: Color(0xFF06013F ),
//                       fontFamily: 'Inter',
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//
//                 Align(
//                   alignment: Alignment.topLeft,
//                   child: Text(
//                     'Evaluate your social anxiety in minutes.',
//                     style: TextStyle(
//                       color: Color.fromRGBO(0, 0, 0, 1),
//                       fontFamily: 'Tuffy',
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//
//                 ListView.builder(
//                   shrinkWrap: true, // Makes ListView not take up more space than it needs
//                   physics: NeverScrollableScrollPhysics(), // Prevents the ListView from scrolling separately
//                   itemCount: questions.length, // Total number of questions
//                   itemBuilder: (context, index) {
//                     final question = questions[index];
//                     return Padding(
//                       padding: const EdgeInsets.all(10.0),
//                       child: QuestionTile(
//                         questionText: question["questionText"],
//                         options: question["options"],
//                         selectedOptionIndex: selectedAnswers[index], // Track the selected option
//                         onOptionSelected: (selectedIndex) {
//                           setState(() {
//                             selectedAnswers[index] = selectedIndex; // Update the selected answer
//                           });
//                         },
//                       ),
//                     );
//                   },
//                 ),
//
//                 MyButton(
//                     text: "Submit",
//                     onPressed:() {}
//                 )
//
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }