import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'category.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = "";
  String _password = "";
  String _errorMessage = "";

  void doLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      var url = Uri.parse("https://ubaya.cloud/flutter/160423025/komiku/login.php");
      
      try {
        var response = await http.post(url, body: {
          'username': _username,
          'password': _password,
        });

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          if (data['result'] == 'OK') {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            int userId = int.parse(data['user_id'].toString());
            await prefs.setInt("user_id", userId);
            await prefs.setString("username", data['username']);
            active_user = data['username'];
            if (!mounted) return; 
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Category()),
            );
          } else {
            setState(() {
              _errorMessage = data['message'];
            });
          }
        } else {
          setState(() {
            _errorMessage = "Server error dengan status: ${response.statusCode}";
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Gagal terhubung ke server: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorOrange = Color(0xFFEC642A);
    const colorSunnyYellow = Color(0xFFFAAA21);
    const colorCream = Color(0xFFFDE2CD);
    const colorCocoa = Color(0xFF642D0A);

    return Scaffold(
      backgroundColor: colorCream,
      appBar: AppBar(
        title: const Text(
          "Login Komiku",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorOrange,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Selamat Datang",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorCocoa,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        style: const TextStyle(color: colorCocoa),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: colorCocoa),
                          prefixIcon: const Icon(Icons.person, color: colorOrange),
                          filled: true,
                          fillColor: colorCream.withOpacity(0.3),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: colorSunnyYellow, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: colorOrange, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? 'Username tidak boleh kosong' : null,
                        onSaved: (value) => _username = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        style: const TextStyle(color: colorCocoa),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: colorCocoa),
                          prefixIcon: const Icon(Icons.lock, color: colorOrange),
                          filled: true,
                          fillColor: colorCream.withOpacity(0.3),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: colorSunnyYellow, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: colorOrange, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) => value!.isEmpty ? 'Password tidak boleh kosong' : null,
                        onSaved: (value) => _password = value!,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: doLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}