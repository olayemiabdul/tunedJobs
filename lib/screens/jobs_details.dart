import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';


import 'package:url_launcher/url_launcher.dart';

import '../provider/favouriteProvider.dart';

class AllJobDetailsPage extends StatefulWidget {
  final dynamic jobDetails;
  final bool isCvLibrary;

  const AllJobDetailsPage({
    super.key,
    required this.jobDetails,
    required this.isCvLibrary,
  });

  @override
  State<AllJobDetailsPage> createState() => _AllJobDetailsPageState();
}

class _AllJobDetailsPageState extends State<AllJobDetailsPage> {

  bool isDescriptionExpanded = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;


  Future<bool?> showAuthenticationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign in for Better Experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sign in to track your applications and get personalized job recommendations.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue as Guest'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await showSignInDialog();
                  if (result == true) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future showSignInDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: signInWithEmail,
              child: const Text('Sign In with Email'),
            ),
          ],
        );
      },
    );
  }
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.of(context).pop(); // Close the dialog after sign-in
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    }
  }

  Future<void> signInWithEmail() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.of(context).pop(); // Close the dialog after sign-in
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email Sign-In failed: $e')),
      );
    }
  }



  Future<void> confirmAndLaunchJob() async {
    final user = FirebaseAuth.instance.currentUser;

    // If the user is already signed in, skip the authentication dialog
    if (user != null) {
      await redirectDialog();
      return;
    }

    // First check if user wants to sign in
    final authResult = await showAuthenticationDialog();

    // User cancelled the dialog
    if (authResult == null) return;

    // Proceed to handle redirect and save
    await redirectDialog();
  }



  Future<void> redirectDialog() async {
    // Show the redirect notice
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redirect Notice'),
        content: Text(
          'You will be redirected to the ${widget.isCvLibrary ? "CV Library" : "Reed"} website. Do you want to continue?',
          style: GoogleFonts.lateef(
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (result == true) {
      final url = Uri.parse(widget.isCvLibrary
          ? "https://www.cv-library.co.uk${widget.jobDetails.url}"
          : widget.jobDetails.jobUrl.toString());

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        final provider = Provider.of<FavouritesJob>(context, listen: false);

        // Save the application if the user is signed in
        if (FirebaseAuth.instance.currentUser != null) {
          if (widget.isCvLibrary) {
            await provider.applyForCvJob(widget.jobDetails);
          } else {
            await provider.applyForReedJob(widget.jobDetails);
          }
        }
      }
    }
  }


  Widget buildJobHeader() {
    final title = widget.isCvLibrary
        ? widget.jobDetails.hlTitle.toString()
        : widget.jobDetails.jobTitle.toString();
    final company = widget.isCvLibrary
        ? widget.jobDetails.agency!.title.toString()
        : widget.jobDetails.employerName.toString();

    return Card(
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        company,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    widget.isCvLibrary
                        ? 'assets/images/cvlogo.png'
                        : 'assets/images/reedlogo.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildJobDetails() {
    final location = widget.isCvLibrary
        ? widget.jobDetails.location.toString()
        : widget.jobDetails.locationName.toString();
    final salary = widget.isCvLibrary
        ? widget.jobDetails.salary.toString()
        : "${widget.jobDetails.minimumSalary} - ${widget.jobDetails.maximumSalary}";
    final date = widget.isCvLibrary
        ? "${widget.jobDetails.posted!.hour} hours ago"
        : "Expires: ${widget.jobDetails.expirationDate}";

    return Card(
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DetailRow(
              icon: Icons.location_on,
              label: 'Location',
              value: location,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            DetailRow(
              icon: Icons.attach_money,
              label: 'Salary',
              value: salary,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            DetailRow(
              icon: Icons.access_time,
              label: 'Posted',
              value: date,
              color: Colors.orange,
            ),
            if (!widget.isCvLibrary && widget.jobDetails.applications != null) ...[
              const SizedBox(height: 16),
              DetailRow(
                icon: Icons.people,
                label: 'Applications',
                value: '${widget.jobDetails.applications} applicants',
                color: Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildJobDescription() {
    final description = widget.isCvLibrary
        ? widget.jobDetails.description.toString()
        : widget.jobDetails.jobDescription.toString();

    return Card(
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  isDescriptionExpanded = !isDescriptionExpanded;
                });
              },
              child: Column(
                children: [
                  Text(
                    description,
                    maxLines: isDescriptionExpanded ? null : 3,
                    overflow: isDescriptionExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDescriptionExpanded ? 'Show Less' : 'Show More',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF7FFFD4),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    final provider = Provider.of<FavouritesJob>(context);

    return ChangeNotifierProvider(
      create: (BuildContext context) => FavouritesJob(),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.blue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back to jobs list',
            ),
            actions: [
              IconButton(
                icon: Icon(
                  widget.isCvLibrary
                      ? provider.cvlikedjobs(widget.jobDetails)
                      ? Icons.favorite
                      : Icons.favorite_border
                      : provider.likedJobs(widget.jobDetails)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () {
                  if (widget.isCvLibrary) {
                    provider.cvtoggleFavourite(widget.jobDetails);
                  } else {
                    provider.toggleFavourite(widget.jobDetails);
                  }
                  provider.saveCvJob(widget.jobDetails);
                  provider.saveReedJob(widget.jobDetails);
                },
                tooltip: 'Save job',
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share(widget.isCvLibrary
                      ? "https://www.cv-library.co.uk${widget.jobDetails.url}"
                      : widget.jobDetails.jobUrl.toString());
                },
                tooltip: 'Share job',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  buildJobHeader(),
                  const SizedBox(height: 16),
                  buildJobDetails(),
                  const SizedBox(height: 16),
                  buildJobDescription(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: confirmAndLaunchJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.launch),
                    SizedBox(width: 8),
                    Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const DetailRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
