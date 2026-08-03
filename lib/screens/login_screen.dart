import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../storage/token_storage.dart';
import 'home_screen.dart';


class LoginScreen extends StatefulWidget {

  const LoginScreen({super.key});


  @override
  State<LoginScreen> createState() => _LoginScreenState();

}



class _LoginScreenState extends State<LoginScreen> {


  final usernameController = TextEditingController();

  final passwordController = TextEditingController();


  bool loading = false;

  String error = '';



  Future<void> login() async {


    setState(() {

      loading = true;
      error = '';

    });



    try {


      final result = await ApiService().login(

        username: usernameController.text.trim(),

        password: passwordController.text.trim(),

      );



      if(result['success'] == true) {


        await TokenStorage.saveTokens(

          result['access'],

          result['refresh'],

        );



        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder: (_) => HomeScreen(

              user: result['user'],

            ),

          ),

        );


      }
      else {


        setState(() {

          error = result['message'] ?? 'اطلاعات ورود صحیح نیست';

        });


      }



    }

    catch(e) {


      setState(() {

        error = 'خطا در ارتباط با سرور';

      });


    }



    setState(() {

      loading = false;

    });


  }





  @override
  Widget build(BuildContext context) {


    return Directionality(

      textDirection: TextDirection.rtl,


      child: Scaffold(


        backgroundColor: const Color(0xff00ACC1),



        body: Center(


          child: SingleChildScrollView(


            padding: const EdgeInsets.all(25),



            child: Card(


              elevation: 10,


              shape: RoundedRectangleBorder(


                borderRadius: BorderRadius.circular(25),


              ),



              child: Padding(


                padding: const EdgeInsets.all(25),



                child: Column(


                  mainAxisSize: MainAxisSize.min,



                  children: [



                    Image.asset(

                      'assets/images/logo.png',

                      width: 250,

                      height: 150,

                    ),



                    // const SizedBox(height:20),



                    // const Text(
                    //
                    //   'ورود به رایا شارژ',
                    //
                    //   style: TextStyle(
                    //
                    //     fontSize:22,
                    //
                    //     fontWeight: FontWeight.bold,
                    //
                    //   ),
                    //
                    // ),



                    const SizedBox(height:30),





                    TextField(


                      controller: usernameController,


                      keyboardType: TextInputType.phone,


                      decoration: InputDecoration(


                        labelText:'شماره موبایل',


                        prefixIcon: const Icon(Icons.phone),


                        border: OutlineInputBorder(

                          borderRadius:

                          BorderRadius.circular(15),

                        ),

                      ),

                    ),




                    const SizedBox(height:20),




                    TextField(


                      controller: passwordController,


                      obscureText:true,


                      decoration: InputDecoration(


                        labelText:'رمز عبور',


                        prefixIcon: const Icon(Icons.lock),


                        border: OutlineInputBorder(

                          borderRadius:

                          BorderRadius.circular(15),

                        ),

                      ),

                    ),




                    const SizedBox(height:20),




                    if(error.isNotEmpty)


                      Text(


                        error,


                        style: const TextStyle(

                          color: Colors.red,

                          fontWeight: FontWeight.bold,

                        ),

                      ),




                    const SizedBox(height:20),





                    SizedBox(


                      width: double.infinity,



                      height:50,



                      child: ElevatedButton(



                        style: ElevatedButton.styleFrom(


                          backgroundColor:

                          const Color(0xff00ACC1),



                          shape: RoundedRectangleBorder(


                            borderRadius:

                            BorderRadius.circular(15),


                          ),


                        ),




                        onPressed:

                        loading ? null : login,





                        child:


                        loading



                            ? const SizedBox(


                          width:25,

                          height:25,


                          child:

                          CircularProgressIndicator(

                            color: Colors.white,

                          ),

                        )



                            :

                        const Text(

                          'ورود',

                          style: TextStyle(

                            color: Colors.white,

                            fontSize:18,

                          ),

                        ),



                      ),

                    )



                  ],


                ),


              ),


            ),


          ),


        ),


      ),

    );


  }


}