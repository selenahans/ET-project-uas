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
            
            // Konversi user_id ke int untuk mengantisipasi jika dari PHP dikirim sebagai String
            int userId = int.parse(data['user_id'].toString());
            await prefs.setInt("user_id", userId);
            await prefs.setString("username", data['username']);
            
            active_user = data['username'];

            // PENTING: Cek mounted sebelum menggunakan context setelah await
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
    return Scaffold(
      appBar: AppBar(title: const Text("Login Komiku")),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value!.isEmpty ? 'Username tidak boleh kosong' : null,
                onSaved: (value) => _username = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Password tidak boleh kosong' : null,
                onSaved: (value) => _password = value!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: doLogin, child: const Text("Login")),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}