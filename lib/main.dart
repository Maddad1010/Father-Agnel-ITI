// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core
import 'package:fragneliti_clone/screens/ShowResult.dart';
import 'package:fragneliti_clone/screens/home.dart';
import 'package:fragneliti_clone/screens/about.dart';
import 'package:fragneliti_clone/screens/curriculum.dart';
import 'package:fragneliti_clone/screens/attendance.dart'; // Import the attendance page
import 'package:fragneliti_clone/screens/login.dart'; // Import the login page
import 'package:fragneliti_clone/screens/classroom.dart'; // Import the classroom page
import 'package:fragneliti_clone/screens/EventCalendar.dart'; // Import the calendar page
import 'package:fragneliti_clone/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fragneliti_clone/screens/contact_us.dart';
import 'package:fragneliti_clone/screens/ChatBotPage.dart'; // Import the ChatBotPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that plugin services are initialized before Firebase

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyACJnOMZYAUYXuaMDP_MxTAS9CURMoSI08",
        appId: "1:99847673222:android:489c1725c9829613bb8807",
        messagingSenderId: "fragneliti",
        projectId: "fragneliti",
      ),
    );
  } catch (e) {
    // Handle initialization error
    print('Firebase initialization error: $e');
    runApp(const ErrorScreen()); // Display an error screen
    return;
  }

  runApp(const FragnelITApp());
}

class FragnelITApp extends StatelessWidget {
  const FragnelITApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fr. Agnel ITI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Set the background color to pure white
      ),
      // Set the initial screen based on login status
      home: FutureBuilder<String?>(
        future: _getStoredUsername(), // Get stored username
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.data != null) {
              // User is logged in, navigate to home page
              return const Home();
            } else {
              // User is not logged in, show login page
              return const LoginWidget();
            }
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginWidget(),
        '/home': (context) => const Home(), // Placeholder until username is passed
        '/about': (context) => const AboutPage(),
        '/curriculum': (context) => const CurriculumPage(),
        '/attendance': (context) => const AttendancePage(),
        '/contact_us': (context) => const ContactPage(),
        '/profile': (context) => const ProfilePage(),
        '/show_result': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return const ShowResultPage(); // Provide a default value if args is null
        },
        '/classroom': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return ClassroomPage(course: args); // Correct the parameter name to 'course'
        },
        '/EventCalendar': (context) => const EventCalendar(), // Add calendar route
        '/chatbot': (context) => const ChatBotPage(), // Add ChatBotPage route
      },
    );
  }

  Future<String?> _getStoredUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username'); // Return the stored username if it exists
  }
}

// Example ErrorScreen widget to show if Firebase initialization fails
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Failed to initialize Firebase. Please try again later.'),
        ),
      ),
    );
  }
}
