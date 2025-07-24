import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientVisitsScreen extends StatelessWidget {
  final String patientId;

  const PatientVisitsScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Notes'),
        backgroundColor: const Color(0xFF078798),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text('No Visits Found.'));
          }

          final visits = snapshot.data!.docs;

          return ListView.builder(
            itemCount: visits.length,
            itemBuilder: (context, index) {
              var visitData = visits[index].data() as Map<String, dynamic>;
              String visitId = visits[index].id;

              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitData['date'] ?? 'Unknown Date',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF078798),
                        ),
                      ),
                      const SizedBox(height: 8),

                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(patientId)
                            .collection('clinical_notes')
                            .where('visit_id', isEqualTo: visitId)
                            .get(),
                        builder: (context, notesSnapshot) {
                          bool hasNotes = notesSnapshot.hasData && notesSnapshot.data!.docs.isNotEmpty;

                          return Align(
                            alignment: Alignment.centerRight,
                            child: hasNotes
                                ? ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VisitNotesScreen(
                                      patientId: patientId,
                                      visitId: visitId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.note, color: Colors.white,),
                              label: const Text('View Notes'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF078798), // Use backgroundColor instead of primary
                                  foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            )
                                : const Text('No Notes Available', style: TextStyle(color: Colors.grey)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class VisitNotesScreen extends StatelessWidget {
  final String patientId;
  final String visitId;

  const VisitNotesScreen({Key? key, required this.patientId, required this.visitId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Note'),
        backgroundColor: const Color(0xFF078798),
      ),
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
            return const Center(child: Text('No Notes Found.'));
          }

          final notes = snapshot.data!.docs;

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
      ),
    );
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
}

