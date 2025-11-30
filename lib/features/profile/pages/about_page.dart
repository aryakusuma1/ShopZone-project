import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color pageBackground = Color(0xFFF8F9FB); // Consistent with HelpPage

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tentang',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Consistent margin
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentang Aplikasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aplikasi ini adalah platform e-commerce yang dirancang untuk memudahkan pengguna dalam berbelanja berbagai produk secara online. Kami menyediakan antarmuka yang ramah pengguna, proses pembayaran yang aman, dan layanan pengiriman yang cepat.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700], // Similar to greyTextColor in HelpPage
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
