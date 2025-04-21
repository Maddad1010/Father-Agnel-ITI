import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rive/rive.dart' as rive; // Alias for Rive
import 'package:fragneliti_clone/screens/home.dart';
import 'package:fragneliti_clone/screens/faq.dart'; // Importing FAQ page

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> with SingleTickerProviderStateMixin {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _passwordVisibility = false;
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadUserData(); // Load user data on startup
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');

    if (username != null) {
      // Automatically navigate to HomePage if already logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    try {
      // Check in students collection
      QuerySnapshot studentSnapshot = await FirebaseFirestore.instance.collection('students').get();
      bool userFound = false;

      for (var studentDoc in studentSnapshot.docs) {
        var studentData = studentDoc.data() as Map<String, dynamic>;
        if (studentData['username'] == username && studentData['pass'] == password) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', studentData['username']);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
          );
          userFound = true;
          break;
        }
      }

      // If not found in students, check in admins
      if (!userFound) {
        QuerySnapshot adminSnapshot = await FirebaseFirestore.instance.collection('admins').get();

        for (var adminDoc in adminSnapshot.docs) {
          var adminData = adminDoc.data() as Map<String, dynamic>;
          if (adminData['username'] == username && adminData['pass'] == password) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', adminData['username']);
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
            userFound = true;
            break;
          }
        }
      }

      if (!userFound) {
        setState(() {
          _errorMessage = 'Invalid username or password.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // This will adjust the layout when the keyboard appears
      body: Stack(
        children: [
          // Background with white color
          Container(
            color: Colors.white,
          ),
          // Rive Animation
          const Positioned.fill(
            child: rive.RiveAnimation.asset(
              'assets/RiveAssets/shapes.riv', // Ensure this path is correct
              fit: BoxFit.cover,
            ),
          ),
          // Login Form
          Center(
            child: SingleChildScrollView( // Make the content scrollable
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20), // Rounded corners
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7), // Semi-transparent background
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Fr. Agnel ITI',
                            style: TextStyle(
                              fontFamily: 'SanFrancisco',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Image.asset(
                          'assets/fragnellogo.png',
                          height: 120,
                          width: 120,
                        ),
                        const SizedBox(height: 30),
                        _buildTextField(_usernameController, 'Username', false),
                        const SizedBox(height: 16),
                        _buildTextField(_passwordController, 'Password', true),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : _buildLoginButton(),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // FAQ button positioned at the top-right corner
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.help_outline, size: 30, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FAQPage()), // Navigate to FAQ page
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isPassword) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_passwordVisibility ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _passwordVisibility = !_passwordVisibility;
                  });
                },
              )
            : null,
      ),
      obscureText: isPassword ? !_passwordVisibility : false,
      style: const TextStyle(color: Colors.black87),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightBlueAccent, // Background color
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Login',
          style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}