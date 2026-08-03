import 'package:flutter/material.dart';


class HomeScreen extends StatelessWidget {


  final Map user;


  const HomeScreen({

    super.key,

    required this.user,

  });



  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title: const Text('پنل کاربری'),

      ),



      body: Center(


        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,


          children: [


            Text(

              'سلام ${user['full_name']}',

              style: const TextStyle(

                fontSize: 22,

              ),

            ),


            const SizedBox(height:20),


            Text(

              'ساختمان: ${user['house_id']}',

            ),


            Text(

              'موبایل: ${user['mobile']}',

            ),


          ],

        ),

      ),

    );


  }

}