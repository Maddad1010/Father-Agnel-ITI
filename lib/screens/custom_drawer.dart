import 'package:flutter/material.dart';
import 'package:fragneliti_clone/screens/login.dart';
import 'package:fragneliti_clone/screens/AdminStudentPanel.dart'; // Import AdminStudentPanel
import 'package:fragneliti_clone/screens/ChatBotPage.dart'; // Import ChatBotPage
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback? logoutCallback;

  const CustomDrawer({super.key, this.logoutCallback});

  Future<Map<String, String>> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');

    String name = '';

    if (username != null && username.isNotEmpty) {
      try {
        var snapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('username', isEqualTo: username)
            .get();

        if (snapshot.docs.isNotEmpty) {
          name = snapshot.docs.first.data()['Name'];
        }
      } catch (e) {
        print('Error retrieving user data: $e');
      }
    }

    return {
      'username': username ?? '',
      'name': name,
    };
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginWidget()),
    );
  }

  Future<void> _adminLogin(BuildContext context) async {
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String username = usernameController.text;
                String password = passwordController.text;

                var snapshot = await FirebaseFirestore.instance
                    .collection('admins')
                    .where('username', isEqualTo: username)
                    .where('pass', isEqualTo: password) // Updated field name
                    .get();

                if (snapshot.docs.isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminStudentPanel()),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Admin credentials are incorrect'),
                    ),
                  );
                }
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<Map<String, String>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Drawer(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Drawer(
            child: Center(child: Text('Error loading user data')),
          );
        }

        final userData = snapshot.data!;
        final username = userData['username']!;
        final name = userData['name']!;

        return Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF305CDE),
                  Colors.blue.shade50,
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF305CDE),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        name.isNotEmpty ? name : 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildMenuItem(
                          icon: Icons.home,
                          title: 'Home',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.info,
                          title: 'About Us',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/about');
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.contact_mail,
                          title: 'Contact Us',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/contact_us');
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.android, // Updated icon to look like a robot
                          title: 'Agnel ChatBot',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ChatBotPage()),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.admin_panel_settings,
                          title: 'Admin Panel',
                          onTap: () {
                            Navigator.pop(context);
                            _adminLogin(context);
                          },
                        ),
                        const Divider(color: Colors.grey),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Log Out',
                          color: Colors.red,
                          onTap: () {
                            if (logoutCallback != null) {
                              logoutCallback!();
                            } else {
                              _logout(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF305CDE)),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.transparent,
      hoverColor: Colors.blue.shade50,
    );
  }
}