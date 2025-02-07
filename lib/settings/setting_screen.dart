import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../screen/firstPage.dart';
import 'contactPage.dart';

class SettingsPageScreen extends StatelessWidget {
  const SettingsPageScreen({super.key});

  privacyPolicy() async {
    const termsUrl =
        'https://doc-hosting.flycricket.io/tuned-jobs-privacy-policy/d8474bc1-13cf-4365-9c1d-1d60a9051883/privacy';
    if (await canLaunch(termsUrl)) {
      await launch(termsUrl);
    } else {
      throw 'Could not launch $termsUrl';
    }
  }

  termsOfService() async {
    const privacyUrl =
        'https://doc-hosting.flycricket.io/tuned-jobs-terms-of-use/cd72c851-b405-4ef2-926d-d9f92e850b54/terms';
    if (await canLaunch(privacyUrl)) {
      await launch(privacyUrl);
    } else {
      throw 'Could not launch $privacyUrl';
    }
  }

  rateUs() async {
    const url = 'https://play.google.com/store/apps/details?id=com.tunedjobs.ukjobsearch';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  contactUs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactUsPage()),
    );
  }

  shareApp(BuildContext context) {
    Share.share(
        'Check out this amazing app: https://play.google.com/store/apps/details?id=com.tunedjobs.ukjobsearch',
        subject: 'Share Our App');
  }

  deleteAccount(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
        ),
      );
    }
  }

  logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Redirect to the main TheWelcomePage()
    navigatorkey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const TheWelcomePage()),
          (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SettingsCard(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              onTap: privacyPolicy,
            ),
            SettingsCard(
              title: 'Terms of Service',
              icon: Icons.rule_outlined,
              onTap: termsOfService,
            ),
            SettingsCard(
              title: 'Rate Us',
              icon: Icons.star_rate_outlined,
              onTap: rateUs,
            ),
            SettingsCard(
              title: 'Contact Us',
              icon: Icons.contact_mail_outlined,
              onTap: () => contactUs(context),
            ),
            SettingsCard(
              title: 'Share App',
              icon: Icons.share_outlined,
              onTap: () => shareApp(context),
            ),
            SettingsCard(
              title: 'Delete Account',
              icon: Icons.delete_forever_outlined,
              onTap: () => deleteAccount(context),
              iconColor: Colors.red,
            ),
            SettingsCard(
              title: 'Logout',
              icon: Icons.logout_outlined,
              onTap: () => logout(context),
              iconColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const SettingsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.green,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
