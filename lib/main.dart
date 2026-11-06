
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';



void main(){

  runApp(

    const RayaChargeApp(),

  );

}



class RayaChargeApp extends StatelessWidget {


  const RayaChargeApp({super.key});



  @override
  Widget build(BuildContext context){


    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'رایا شارژ',

      theme: ThemeData(

        fontFamily: 'Vazir',

        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xffffffff),
        ),

      ),

      home: const SplashScreen(),

    );


  }

}
