
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:supabase/supabase.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import '../../controllers/product_controller.dart';
import 'home_screen.dart';

class PageVerifyOtp extends StatelessWidget {
  PageVerifyOtp({super.key, required this.email});
  String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Xác thực mã OTP"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OtpTextField(
            numberOfFields: 6,
            borderColor: Color(0xFF512DA8),
            //set to true to show as box or false to show as dash
            showFieldAsBox: true,
            //runs when a code is typed in
            onCodeChanged: (String code) {
              //handle validation or checks here
            },
            //runs when every textfield is filled
            onSubmit: (String verificationCode) async {
              var response = await Supabase.instance.client.auth.verifyOTP(
                  email: email,
                  type: OtpType.email,
                  token: verificationCode
              );
              if (response?.session != null && response?.user != null){
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomePageFood(),),
                      (route) => false,
                );
              }
            }, // end onSubmit
          ),
          SizedBox(height: 50,),
          ElevatedButton(
            onPressed: () async {
              showSnackBar(context, message: "Đang gửi mã OTP ...", seconds: 600);
              final response = await supabase.auth.signInWithOtp(email: email);
              showSnackBar(context, message: "Mã OTP đã được gửi vào ${email}", seconds: 3);
            },
            child: Text("Gửi lại mã OTP"),
          )
        ],
      ),
    );
  }
}

void showSnackBar(BuildContext context, {required String message, int seconds = 3}){
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: seconds),)
  );
}
