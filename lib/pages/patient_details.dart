import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientDetails extends StatelessWidget {
  final String patientId;

  const PatientDetails({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: Color(0xFF078798),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Patient data not found.'));
          }

          final patientData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(patientData),
                const SizedBox(height: 20),
                _buildInfoSection(patientData),
                const SizedBox(height: 20),
                _buildFeedbackSection(context, patientId),
                const SizedBox(height: 20),
                _buildRecentVisitsSection(context, patientId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> patientData) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Color(0xFF078798),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/images/patient1.jpg'),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patientData['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Age: ${patientData['age'] ?? 'N/A'}, ${patientData['gender'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Occupation: ${patientData['occupation'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> patientData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('First Name', patientData['firstName'] ?? 'N/A'),
            _buildInfoRow('Last Name', patientData['lastName'] ?? 'N/A'),
            _buildInfoRow('Email', patientData['email'] ?? 'N/A'),
            _buildInfoRow('Contact', patientData['contact'] ?? 'N/A'),
            // _buildInfoRow('Date of Birth', patientData['dob'] ?? 'N/A'),
            _buildInfoRow('Marital Status', patientData['maritalStatus'] ?? 'N/A'),
            _buildInfoRow('Previous Medication', patientData['previousMedication'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildRecentVisitsSection(BuildContext context, String patientId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Visits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(patientId)
                  .collection('appointments')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent visits found.'));
                }

                final visits = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visits.length,
                  itemBuilder: (context, index) {
                    var visitData = visits[index].data() as Map<String, dynamic>;
                    String visitId = visits[index].id;

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(patientId)
                          .collection('clinical_notes')
                          .where('visit_id', isEqualTo: visitId)
                          .get(),
                      builder: (context, notesSnapshot) {
                        bool hasNotes = notesSnapshot.hasData &&
                            notesSnapshot.data!.docs.isNotEmpty;

                        return ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.teal),
                          title: Text(visitData['date'] ?? 'Unknown Date'),
                          subtitle: Text(visitData['summary'] ?? 'No details available'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              if (hasNotes) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClinicalNotesScreen(
                                      patientId: patientId,
                                      visitId: visitId,
                                    ),
                                  ),
                                );
                              } else {
                                _addClinicalNoteDialog(context, patientId, visitId);
                              }
                            },
                            child: Text(hasNotes ? 'View' : 'Add Note'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addClinicalNoteDialog(BuildContext context, String patientId, String visitId) {
    TextEditingController objectiveController = TextEditingController();
    TextEditingController assessmentController = TextEditingController();
    TextEditingController planController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Clinical Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: objectiveController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Objective',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: assessmentController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Assessment',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: planController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Plan',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String objective = objectiveController.text.trim();
                String assessment = assessmentController.text.trim();
                String plan = planController.text.trim();

                if (objective.isNotEmpty && assessment.isNotEmpty && plan.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(patientId)
                      .collection('clinical_notes')
                      .add({
                    'visit_id': visitId,
                    'objective': objective,
                    'assessment': assessment,
                    'plan': plan,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clinical note added successfully!')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackSection(BuildContext context, String patientId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Feedback',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(patientId)
                  .collection('feedback')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No feedback available.');
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var feedbackData = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(feedbackData['feedback'] ?? 'No feedback'),
                      subtitle: Text(feedbackData['timestamp'].toDate().toString()),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ClinicalNotesScreen extends StatelessWidget {
  final String patientId;
  final String visitId;

  const ClinicalNotesScreen({Key? key, required this.patientId, required this.visitId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Notes',style: TextStyle(color: Colors.white)),backgroundColor:  Color(0xFF078798),),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(patientId)
            .collection('clinical_notes')
            .where('visit_id', isEqualTo: visitId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No clinical notes found.'));
          }

          final notes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              var noteData = notes[index].data() as Map<String, dynamic>;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: notes.map((doc) {
                    var noteData = doc.data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Objective'),
                          _buildSectionContent(noteData['objective']),
                          const SizedBox(height: 10),
                          _buildSectionTitle('Assessment'),
                          _buildSectionContent(noteData['assessment']),
                          const SizedBox(height: 10),
                          _buildSectionTitle('Plan'),
                          _buildSectionContent(noteData['plan']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
Widget _buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF078798),
      ),
    ),
  );
}

Widget _buildSectionContent(String? content) {
  return Text(
    content ?? 'No data available',
    style: const TextStyle(
      fontSize: 16,
      color: Colors.black87,
      height: 1.5, // This adds line height to make the text easier to read
    ),
  );
}
