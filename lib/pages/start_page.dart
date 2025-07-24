import 'package:flutter/material.dart';
import 'package:app/pages/login_page.dart';
import 'package:app/pages/register_page.dart';
import 'package:app/util/my_button.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Image.asset(
                  'lib/images/img.png',
                  height: 250,
                  width: 250,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  "eTherapist",
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontStyle: FontStyle.italic,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  "Embrace Life, Overcome Anxiety",
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: 15,),
              MyButton(
                  text: "LogIn",
                  onPressed:() {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );}),
              SizedBox(height: 15,),
              MyButton(
                  text: "SignUp",
                  onPressed: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Register()),
                    );}),
            ],
          ),
        ),
      ),
    );
  }
}
