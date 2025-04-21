import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeBoard extends StatefulWidget {
  const NoticeBoard({super.key});

  @override
  _NoticeBoardState createState() => _NoticeBoardState();
}

class _NoticeBoardState extends State<NoticeBoard> {
  String title = '';
  String date = '';
  String content = '';
  String category = 'Events'; // Default category
  List<DocumentSnapshot> selectedNotices = []; // Store selected notices
  Set<String> clickedNotices = {}; // Track clicked notices

  // Function to handle admin login before adding notice
  Future<void> _showAdminLoginDialog(Function callback) async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Login'),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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

                // Check admin credentials from Firestore
                try {
                  DocumentSnapshot adminSnapshot = await FirebaseFirestore
                      .instance
                      .collection('admins')
                      .where('username', isEqualTo: username)
                      .where('pass', isEqualTo: password)
                      .limit(1)
                      .get()
                      .then((QuerySnapshot querySnapshot) =>
                          querySnapshot.docs.first);

                  if (adminSnapshot.exists) {
                    Navigator.of(context).pop(); // Close login dialog
                    callback(); // Call the provided callback function
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Invalid username or password')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid username or password')),
                  );
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close login dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Function to show the dialog for adding a notice
  void _showAddNoticeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Notice'),
              content: SingleChildScrollView( // Make the content scrollable
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (value) {
                        setState(() {
                          title = value;
                        });
                      },
                    ),
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'Date (yyyy-mm-dd)'),
                      onChanged: (value) {
                        setState(() {
                          date = value;
                        });
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Content'),
                      onChanged: (value) {
                        setState(() {
                          content = value;
                        });
                      },
                      maxLines: 3,
                    ),
                    DropdownButton<String>(
                      value: category,
                      onChanged: (String? newValue) {
                        setState(() {
                          category = newValue!;
                        });
                      },
                      items: <String>['Events', 'Holiday', 'Important', 'Exam']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Add Notice'),
                  onPressed: () {
                    if (title.isNotEmpty &&
                        date.isNotEmpty &&
                        content.isNotEmpty) {
                      _addNotice(title, date, content, category);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill in all fields.')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to add a notice to Firestore
  Future<void> _addNotice(
      String title, String date, String content, String category) async {
    try {
      await FirebaseFirestore.instance.collection('notices').add({
        'title': title,
        'date': date,
        'content': content,
        'category': category,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice added successfully!')),
      );
    } catch (e) {
      print('Error adding notice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add notice')),
      );
    }
  }

  // Function to show delete confirmation dialog
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
              'Are you sure you want to delete the selected notice(s)?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteNotices(selectedNotices);
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete selected notices
  Future<void> _deleteNotices(List<DocumentSnapshot> selectedNotices) async {
    for (var notice in selectedNotices) {
      await FirebaseFirestore.instance
          .collection('notices')
          .doc(notice.id)
          .delete();
    }
    setState(() {
      selectedNotices.clear(); // Clear selected notices after deletion
      clickedNotices.clear(); // Clear clicked notices after deletion
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notice(s) deleted successfully!')),
    );
  }

  // Function to select and delete multiple notices
  void _showDeleteNoticesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Notices to Delete'),
          content: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('notices').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var notices = snapshot.data!.docs;
              return SingleChildScrollView(
                child: Column(
                  children: notices.map((notice) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (clickedNotices.contains(notice.id)) {
                            clickedNotices.remove(notice.id);
                            selectedNotices.remove(notice);
                          } else {
                            clickedNotices.add(notice.id);
                            selectedNotices.add(notice);
                          }
                        });
                      },
                      child: Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        color: clickedNotices.contains(notice.id)
                            ? Colors.red
                            : Colors.white, // Change color on click
                        child: ListTile(
                          title: Text(notice['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${notice['date']}'),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${notice['category']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight
                                      .bold, // Display the category in bold
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(notice['content']),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedNotices.isNotEmpty) {
                  _showDeleteConfirmationDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No notice selected for deletion.')),
                  );
                }
              },
              child: const Text('Delete Selected'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
        backgroundColor: const Color(0xFF305CDE), // iOS-like royal blue
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showAdminLoginDialog(
                  _showDeleteNoticesDialog); // Login before delete
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notices').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var notices = snapshot.data!.docs;
          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, index) {
              var notice = notices[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (clickedNotices.contains(notice.id)) {
                      clickedNotices.remove(notice.id);
                      selectedNotices.remove(notice);
                    } else {
                      clickedNotices.add(notice.id);
                      selectedNotices.add(notice);
                    }
                  });
                },
                child: Card(
                  elevation: 2.0,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: clickedNotices.contains(notice.id)
                      ? Colors.red
                      : Colors.white, // Change color on click
                  child: ListTile(
                    title: Text(notice['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${notice['date']}'),
                        Text(
                          'Category: ${notice['category']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, // Display the category in bold
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(notice['content']),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAdminLoginDialog(
              _showAddNoticeDialog); // Login before adding a notice
        },
        backgroundColor: const Color(0xFF305CDE), // iOS-like royal blue
        child: const Icon(Icons.add),
      ),
    );
  }
}
