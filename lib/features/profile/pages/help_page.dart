import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color greyTextColor = Color(0xFF6B7280);
    const Color linkColor = Color(0xFF3B82F6);
    const Color pageBackground = Color(0xFFF8F9FB);

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
          'Bantuan',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Pertanyaan Umum
              const Text(
                'Pertanyaan Umum',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                question: 'Bagaimana cara memesan?',
                answer:
                    'Untuk memesan, pilih produk, tambahkan ke keranjang, lalu lanjutkan ke pembayaran.',
                textColor: greyTextColor,
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                question: 'Bagaimana cara melacak pesanan?',
                answer:
                    "Untuk melacak pesanan Anda, kunjungi bagian 'Pesanan Saya'.",
                textColor: greyTextColor,
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                question: 'Bagaimana cara mengembalikan barang?',
                answer:
                    'Untuk mengembalikan barang, kunjungi bagian refund saya di akun anda.',
                textColor: greyTextColor,
              ),

              const SizedBox(height: 24),

              // Bagian Kontak
              const Text(
                'Kontak',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildContactItem(
                title: 'Email Support',
                contact: 'support@shopzone.com',
                icon: Icons.email_outlined,
                linkColor: linkColor,
                textColor: greyTextColor,
              ),
              const SizedBox(height: 16),
              _buildContactItem(
                title: 'Nomor Telepon Support',
                contact: '+62 812 3456 7890',
                icon: Icons.phone_outlined,
                linkColor: linkColor,
                textColor: greyTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required String title,
    required String contact,
    required IconData icon,
    required Color linkColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: textColor)),
              const SizedBox(height: 2),
              Text(
                contact,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: linkColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
