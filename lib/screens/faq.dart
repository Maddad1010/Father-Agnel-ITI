import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FAQSection(
            title: 'About Fr. Agnel I.T.I.',
            faqs: [
              FAQItem(
                question: 'What is the mission of Fr. Agnel I.T.I.?',
                answer:
                    'Our mission is to develop each student into a complete individual guided by a strong value system, confidence, and awareness of their surroundings.',
              ),
              FAQItem(
                question: 'What is the vision of Fr. Agnel I.T.I.?',
                answer:
                    'Our vision is rooted in excellence and continuous improvement in academics and practical training, ensuring holistic development for every student.',
              ),
              FAQItem(
                question: 'When was the institute established?',
                answer: 'The institute was established in August 1991.',
              ),
            ],
          ),
          FAQSection(
            title: 'Courses & Admissions',
            faqs: [
              FAQItem(
                question: 'What courses are offered?',
                answer:
                    'We offer vocational training in trades such as:\n• Mechanic Motor Vehicle (MMV)\n• Fitter (FT)\n• Electrician (ET)\n• Mechanic Refrigeration & Air-Conditioning',
              ),
              FAQItem(
                question: 'How can I apply for admission?',
                answer:
                    'Admissions are conducted online via the government website: https://admission.dvet.gov.in/',
              ),
              FAQItem(
                question: 'Who is eligible to apply?',
                answer:
                    'Eligibility criteria follow the guidelines of the Directorate of Vocational Education and Training (DVET), Maharashtra.',
              ),
            ],
          ),
          FAQSection(
            title: 'Facilities & Student Development',
            faqs: [
              FAQItem(
                question: 'What library facilities are available?',
                answer:
                    'We have an up-to-date library open from 7:00 AM to 11:00 PM.',
              ),
              FAQItem(
                question: 'Are there extracurricular activities?',
                answer:
                    'Yes, we organize an Annual Technical Exhibition in February where students showcase projects.',
              ),
              FAQItem(
                question: 'Does the institute provide placement assistance?',
                answer:
                    'Yes, we connect students with industry partners for job opportunities.',
              ),
            ],
          ),
          FAQSection(
            title: 'Rules & Regulations',
            faqs: [
              FAQItem(
                question: 'Are mobile phones allowed on campus?',
                answer: 'No, mobile phones are strictly banned within the premises.',
              ),
              FAQItem(
                question: 'What are the rules regarding identity cards?',
                answer:
                    'Every student is issued an Identity Card and must carry it at all times within the campus.',
              ),
              FAQItem(
                question: 'When are certificates issued to students?',
                answer:
                    'Certificates are issued only after payment of all dues and successful course completion.',
              ),
            ],
          ),
          FAQSection(
            title: 'Login & Online Access',
            faqs: [
              FAQItem(
                question: 'How do I log in to my student account?',
                answer:
                    'Students will receive their username and password from the administration.',
              ),
              FAQItem(
                question: 'Where can I access study materials and results?',
                answer:
                    'Study materials and results are available through the official portal or administration notifications.',
              ),
            ],
          ),
          FAQSection(
            title: 'Contact Information',
            faqs: [
              FAQItem(
                question: 'How can I contact Fr. Agnel I.T.I.?',
                answer:
                    'Phone Numbers:\n• 022 2777 1069 (Principal Sir)\n• 92213 86274 (Chaudhari Sir)\n• 86552 26712 (Kondekar Sir)\n\nEmail: agneliti@yahoo.co.in\n\nOffice Hours: 09:00 AM - 05:00 PM\n\nAddress: Sector 9A, Vashi, Navi Mumbai',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FAQSection extends StatelessWidget {
  final String title;
  final List<FAQItem> faqs;

  const FAQSection({super.key, required this.title, required this.faqs});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: faqs.map((faq) => FAQTile(faq: faq)).toList(),
      ),
    );
  }
}

class FAQTile extends StatelessWidget {
  final FAQItem faq;

  const FAQTile({super.key, required this.faq});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            faq.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            faq.answer,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
