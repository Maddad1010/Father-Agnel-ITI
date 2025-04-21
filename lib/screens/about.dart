// lib/screens/about.dart
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: const Color(0xFF305CDE),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Allows scrolling
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Displaying the banner image
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image:AssetImage('assets/courses-banner.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'About Us',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Text(
                'Our Aim',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.green),
              ),
              const Text(
                'To promote the brotherhood of mankind through our Educational, Cultural, and Charitable Institutions. On the 9th of June, 1957, the Fr. Agnel Ashram was established at Land’s End, Bandstand, Bandra in Mumbai with a vision to foster love and understanding among the various communities in India and also to contribute to development and self-reliance through education. Under the inspiration and guidance of the founder Fr. C. Rodriguez and a dedicated few, the movement started with an orphanage and trade school in carpentry. From this humble beginning today this movement has grown into a Universal family (Vasudhaiva Kutumbakam) which aims to promote the universal family bonded with love, brotherhood & and compassion. Under the guidance of the Agnel Ashram fathers, it caters to full fledge schools, Industrial Training Centers, Polytechnic, Engineering Colleges at the bachelor and post-graduate levels, and a school of management and has spread across the country with large technical educational complexes at Vashi in Navi Mumbai, Bandra in Mumbai, Verna in Goa, New Delhi, Noida, Greater Noida, Ambernath, and Pune.Every center has the unique distinction of having an orphanage where needy orphanages of all age groups are housed, clothed, fed, and educated free of cost till they find a suitable profession and settle in life.',
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),
              const Text(
                'Our Mission',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const Text(
                'To develop each student to be a complete person, guided by a value system drawn from a strong, confident, and lucid attitude, nurtured by knowledge of the self and surroundings and projected from the larger perspective of society and the environment. We aim to develop confident and motivated individuals who share a strong bond with nature and humanity. Blended with a passion for the art of self-management.',
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),
              const Text(
                'Our Vision',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Our value for excellence and concomitant quest for continuous improvement in every field of our education and work shape our vision.The Government of Maharashtra through their G.R.No.PTI/1091/(921)Vocational Training Dt. 28th August 1991 granted permission to start an I.T.I at Vashi in August 1991.The Kind of Education we impart.High standards of academic as well as practical education are provided to each student, by using appropriate and modern teaching aids and equipment including Audio video aids. In order to achieve a complete formation and all-around progress of the personality together with high-level academic achievements, special care is taken to give them all the facilities to facilitate the full blossoming of their talents. The task of imbibing each student with patriotism, honesty, and the secular and social outlook of life, conducive to making him/her a citizen Enlighted with knowledge and wisdom, is the driving force and spirit permeating all our activities and endeavours in the education field.',
                textAlign: TextAlign.justify,
              ),
              
              const SizedBox(height: 16),
              const Text(
                'The motto of I.T.I.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const Text(
                '“Love your neighbour as yourself ” is the motto of this I.T.I. This principle is impregnated in each and every plan and program of the I.T.I. which alone is the best device and driving force to foster in every student the quality of national integration, Uprightness and brotherhood in love and oneness.',
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
