import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';



class SplashScreen extends StatefulWidget {

  const SplashScreen({super.key});


  @override
  State<SplashScreen> createState() => _SplashScreenState();

}



class _SplashScreenState extends State<SplashScreen> {


  String appDescription = '';

  final String fullDescription = 'مدیریت مجتمع مسکونی رایا شارژ';

  int index = 0;



  @override
  void initState() {

    super.initState();


    startTextAnimation();


    Timer(

      const Duration(seconds: 10),

          () {

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder: (_) => const LoginScreen(),

          ),

        );

      },

    );

  }





  void startTextAnimation(){


    Timer.periodic(

      const Duration(milliseconds: 120),

          (timer){


        if(index < fullDescription.length){


          setState(() {

            appDescription += fullDescription[index];

            index++;

          });


        }

        else {

          timer.cancel();

        }


      },

    );


  }






  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor: const Color(0xff00ACC1),


      body: SafeArea(


        child: Column(


          children: [


            Expanded(


              child: Center(


                child: Column(


                  mainAxisSize: MainAxisSize.min,


                  children: [



                    Container(

                      width: 160,

                      height: 160,


                      decoration: const BoxDecoration(

                        color: Colors.white,

                        shape: BoxShape.circle,

                      ),


                      padding: const EdgeInsets.all(25),


                      child: Image.asset(

                        'assets/images/splash_logo.png',

                      ),


                    ),



                  ],


                ),

              ),

            ),




            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 20),


              child: Text(

                appDescription,


                textAlign: TextAlign.center,


                style: const TextStyle(

                  fontSize: 16,

                  fontWeight: FontWeight.w500,

                  color: Colors.white,

                  letterSpacing: 1,

                ),

              ),

            ),



            const SizedBox(height: 20),




            const Padding(

              padding: EdgeInsets.only(bottom: 30),


              child: Text(

                'نسخه 5.2.0',


                style: TextStyle(

                  fontSize: 12,

                  color: Colors.white70,

                ),

              ),

            ),



          ],

        ),


      ),


    );


  }


}