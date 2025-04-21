import 'package:flutter/material.dart';
import 'package:fragneliti_clone/screens/custom_drawer.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the screen dimensions
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
      
        backgroundColor: const Color(0xFF305CDE),
          foregroundColor: Colors.white,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.04), // Responsive padding
        child: SingleChildScrollView( // Added to handle overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Icon(Icons.school, color: Colors.blue[900], size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fr.Agnel Technical Education Complex\nIndustrial Training Institute (Pvt)',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                        shadows: [
                          Shadow(
                            offset: const Offset(1.5, 1.5),
                            blurRadius: 3.0,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.blue[900], size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sector 9A, Vashi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Navi Mumbai',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '400703',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                height: 32,
                thickness: 1.5,
                color: Colors.blue[900],
                indent: 10,
                endIndent: 10,
              ),
              _buildContactCard(
                icon: Icons.phone,
                label: 'Contact Numbers',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildContactRow('02227771069', 'Principal Sir'),
                    _buildContactRow('9221386274', 'Chaudhari Sir'),
                    _buildContactRow('8655226712', 'Kondekar Sir'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildContactCard(
                icon: Icons.email,
                label: 'Email',
                content: Text(
                  'agneliti@yahoo.co.in',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5,
      shadowColor: Colors.blue[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: Colors.blue[900], size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  content,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(String number, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded( // Use Expanded to ensure it takes available space
          child: Text(
            number,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            overflow: TextOverflow.visible, // Show full text
          ),
        ),
        const SizedBox(width: 8), // Space between number and name
        Expanded( // Use Expanded to ensure it takes available space
          child: Text(
            name,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            overflow: TextOverflow.visible, // Show full text
          ),
        ),
      ],
    );
  }
}
