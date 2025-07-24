import 'package:flutter/material.dart';

class Appointment {
  final String name;
  final String time;

  Appointment({
    required this.name,
    required this.time,
  });
}

class AppointmentCard extends StatelessWidget {
  final String name;
  final String date;
  final String time;

  const AppointmentCard({
    required this.name,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top : 30, left: 30),
      child: Container(
        width: 372,
        height: 61,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color.fromRGBO(7, 135, 152, 0.58),
          border: Border.all(
            color: const Color.fromRGBO(151, 151, 151, 1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: const TextStyle(
                  color: Color.fromRGBO(23, 20, 20, 1.0),
                  fontFamily: 'ADLaM Display',
                  fontSize: 14,
                ),
              ),
              Row(
                children: <Widget>[
                  const Text(
                    'Date: ',
                    style: TextStyle(
                      color: Color.fromRGBO(9, 10, 10, 1),
                      fontFamily: 'ADLaM Display',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color.fromRGBO(9, 10, 10, 1),
                      fontFamily: 'Abyssinica SIL',
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Time: ',
                    style: TextStyle(
                      color: Color.fromRGBO(9, 10, 10, 1),
                      fontFamily: 'ADLaM Display',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color.fromRGBO(9, 10, 10, 1),
                      fontFamily: 'Abyssinica SIL',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
