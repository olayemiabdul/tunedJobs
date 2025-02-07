import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';

import 'package:share_plus/share_plus.dart';
import 'profile_model.dart';
import '../settings/setting_screen.dart';

class WelcomeHomeScreen extends StatefulWidget {
  const WelcomeHomeScreen({super.key});

  @override
  State<WelcomeHomeScreen> createState() => _WelcomeHomeScreenState();
}

class _WelcomeHomeScreenState extends State<WelcomeHomeScreen> {
  PlatformFile? pickedFiles;
  String? downloadUrl;
  bool isEditing = false;
  final formKey = GlobalKey<FormState>();
  //pdf file
  late PDFViewController? pdfViewController;
  int totalPages = 0;
  int currentPage = 0;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController preferredJobController = TextEditingController();
  final TextEditingController currentJobController = TextEditingController();

  UserProfile? userProfile;
  late double screenWidth;
  late double screenHeight;
  late Orientation orientation;
  @override
  void initState() {
    super.initState();
    loadUserProfile();
    loadResume();
    if (userProfile != null) {
      currentJobController.text=userProfile?.currentJob??'';
      preferredJobController.text=userProfile?.preferredJob??'';
      firstNameController.text = userProfile?.firstName ?? '';
      lastNameController.text = userProfile?.lastName ?? '';
    }
  }

  Widget _buildPlatformSpecificAppBar() {
    // if (Platform.isIOS) {
    //   return CupertinoNavigationBar(
    //     middle: Text(
    //       'Profile',
    //       style: GoogleFonts.poppins(
    //         color: CupertinoColors.white,
    //         fontWeight: FontWeight.w600,
    //       ),
    //     ),
    //     backgroundColor: CupertinoColors.systemGreen,
    //     trailing: Row(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         CupertinoButton(
    //           padding: EdgeInsets.zero,
    //           onPressed: () {
    //             if (downloadUrl != null) {
    //               Share.share('Here is my uploaded resume: $downloadUrl');
    //             } else {
    //               _showPlatformAlert('No resume uploaded to share.');
    //             }
    //           },
    //           child: const Icon(CupertinoIcons.share, color: CupertinoColors.white),
    //         ),
    //         CupertinoButton(
    //           padding: EdgeInsets.zero,
    //           onPressed: () => Navigator.push(
    //             context,
    //             CupertinoPageRoute(builder: (_) => const SettingsPageScreen()),
    //           ),
    //           child: const Icon(CupertinoIcons.settings, color: CupertinoColors.white),
    //         ),
    //       ],
    //     ),
    //   );
    // }

    return AppBar(
      backgroundColor: const Color(0xFFFFE0C2),
      title: Text(
        'Profile',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            if (downloadUrl != null) {
              Share.share('Here is my uploaded resume: $downloadUrl');
            } else {
              _showPlatformAlert('No resume uploaded to share.');
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPageScreen()),
          ),
        ),
      ],
    );
  }

  void _showPlatformAlert(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Alert'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  Widget buildProfileHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final imageSize = screenWidth * 0.3; // Responsive image size

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Platform.isIOS ? CupertinoColors.white : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          SizedBox(height: screenHeight * 0.02),
          // Name and other profile information...
          buildProfileInfo(),
          SizedBox(height: screenHeight * 0.02),

        ],
      ),
    );
  }
  Widget _buildCameraButton() {
    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: pickAndUploadImage,
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            color: CupertinoColors.activeGreen,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(CupertinoIcons.camera, color: CupertinoColors.white),
        ),
      );
    }

    return InkWell(
      onTap: pickAndUploadImage,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget buildProfileInfo() {
    final textScale = MediaQuery.of(context).textScaleFactor;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: userProfile?.customImageUrl != null
                    ? (userProfile!.customImageUrl!.startsWith('http')
                    ? NetworkImage(userProfile!.customImageUrl!)
                    : FileImage(File(userProfile!.customImageUrl!)) as ImageProvider)
                    : const AssetImage('assets/default_profile.png'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: pickAndUploadImage, // Open image picker
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.02),

        if (!isEditing) ...[
          // View Mode
          Text(
            '${userProfile?.firstName ?? ''} ${userProfile?.lastName ?? ''}',
            style: GoogleFonts.poppins(
              fontSize: 22 * textScale,
              fontWeight: FontWeight.bold,
              color: Platform.isIOS ? CupertinoColors.label : Colors.black87,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Divider(
            color: Platform.isIOS ? CupertinoColors.systemGrey4 : Colors.grey[300],
          ),
          SizedBox(height: screenHeight * 0.02),
          ...buildProfileRows(), // Display other profile details
          SizedBox(height: screenHeight * 0.03),
          ElevatedButton(
            onPressed: () => setState(() => isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Edit Profile',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ] else ...[
          // Edit Mode
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 20 * textScale,
                    fontWeight: FontWeight.w600,
                    color: Platform.isIOS ? CupertinoColors.label : Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                buildFormField(
                  controller: firstNameController,
                  label: 'First Name',
                  icon: Platform.isIOS ? CupertinoIcons.person : Icons.person_outline,
                ),
                SizedBox(height: screenHeight * 0.016),
                buildFormField(
                  controller: lastNameController,
                  label: 'Last Name',
                  icon: Platform.isIOS ? CupertinoIcons.person : Icons.person_outline,
                ),
                SizedBox(height: screenHeight * 0.016),
                buildFormField(
                  controller: currentJobController,
                  label: 'Current Job',
                  icon: Platform.isIOS ? CupertinoIcons.briefcase : Icons.work_outline,
                ),
                SizedBox(height: screenHeight * 0.016),
                buildFormField(
                  controller: preferredJobController,
                  label: 'Preferred Job',
                  icon: Platform.isIOS ? CupertinoIcons.briefcase : Icons.work_outline,
                ),
                SizedBox(height: screenHeight * 0.016),
                buildFormField(
                  controller: locationController,
                  label: 'Location',
                  icon: Platform.isIOS ? CupertinoIcons.location : Icons.location_on_outlined,
                ),
                SizedBox(height: screenHeight * 0.016),
                buildFormField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Platform.isIOS ? CupertinoIcons.phone : Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: screenHeight * 0.024),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (Platform.isIOS)
                      CupertinoButton(
                        onPressed: () => setState(() => isEditing = false),
                        child: const Text('Cancel'),
                      )
                    else
                      TextButton(
                        onPressed: () => setState(() => isEditing = false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    SizedBox(width: screenWidth * 0.04),
                    if (Platform.isIOS)
                      CupertinoButton.filled(
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            updateUserProfile();
                          }
                        },
                        child: const Text('Save'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            updateUserProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                            vertical: screenHeight * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }


  List<Widget> buildProfileRows() {
    final user = FirebaseAuth.instance.currentUser;
    final infoItems = [
      {
        'icon': FontAwesomeIcons.briefcase,
        'title': 'Current Job',
        'value': userProfile?.currentJob ?? 'Not specified',
      },
      {
        'icon': FontAwesomeIcons.userTie,
        'title': 'Preferred Job',
        'value': userProfile?.preferredJob ?? 'Not specified',
      },
      {
        'icon': FontAwesomeIcons.locationDot,
        'title': 'Location',
        'value': userProfile?.location ?? 'Not specified',
      },
      {
        'icon': FontAwesomeIcons.phoneVolume,
        'title': 'Location',
        'value': userProfile?.phone?? 'Not specified',
      },
      {
        'icon': FontAwesomeIcons.message,
        'title': 'Location',
        'value': user!.email?? 'Not specified',
      },
      // Add other profile rows...
    ];

    return infoItems.map((item) => buildProfileRow(
      icon: item['icon'] as IconData,
      title: item['title'] as String,
      value: item['value'] as String,
    )).toList();
  }

  Widget buildEditButton() {

    if (Platform.isIOS) {
      // iOS-specific button
      return CupertinoButton(
        color: CupertinoColors.activeGreen,
        borderRadius: BorderRadius.circular(12),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.08,
          vertical: screenHeight * 0.015,
        ),
        onPressed: () => setState(() => isEditing = true),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.pencil),
            SizedBox(width: screenWidth * 0.02),
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      // Android-specific button
      return ElevatedButton.icon(
        onPressed: () => setState(() => isEditing = true),
        icon: const Icon(Icons.edit),
        label: const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.015,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }











  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userProfile = UserProfile.fromMap(doc.data()!);
          preferredJobController.text=userProfile?.preferredJob??'';
          currentJobController.text=userProfile?.currentJob??'';
          locationController.text = userProfile?.location ?? '';

          phoneController.text = userProfile?.phone ?? '';
        });
      }
    }
  }

  Future<void> updateUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final updatedProfile = {
        'preferredJob':preferredJobController.text,
        'currentJob':currentJobController.text,
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'location': locationController.text,
        'phone': phoneController.text,
        'customImageUrl': userProfile?.customImageUrl,
      };

      await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .set(updatedProfile, SetOptions(merge: true));

      setState(() {
        userProfile = UserProfile(

          firstName: firstNameController.text,
          currentJob: currentJobController.text,
          preferredJob: preferredJobController.text,
          lastName: lastNameController.text,
          location: locationController.text,
          phone: phoneController.text,
          customImageUrl: userProfile?.customImageUrl,
        );
        isEditing = false;
      });
    }
  }



  Future<void> pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final file = File(image.path);

        // Show image immediately (before uploading)
        final temporaryUrl = file.path;

        setState(() {
          userProfile = userProfile?.copyWith(customImageUrl: temporaryUrl) ??
              UserProfile(
                customImageUrl: temporaryUrl,
                location: userProfile?.location ?? '',
                phone: userProfile?.phone ?? '',
                firstName: userProfile?.firstName ?? '',
                lastName: userProfile?.lastName ?? '',
                currentJob: userProfile?.currentJob ?? '',
                preferredJob: userProfile?.preferredJob ?? '',
              );
        });

        // Upload image to Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(user.uid)
            .child('profile.jpg');

        await ref.putFile(file);
        final imageUrl = await ref.getDownloadURL();

        // Update Firestore with the uploaded image URL
        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(user.uid)
            .update({'customImageUrl': imageUrl});

        // Update UI with the real image URL from Firebase
        setState(() {
          userProfile = userProfile?.copyWith(customImageUrl: imageUrl);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
    }
  }

  Future<void> pickAndUploadResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final file = File(result.files.single.path!);
        final ref = FirebaseStorage.instance
            .ref()
            .child('resumes')
            .child(user.uid)
            .child(result.files.single.name); // Put filename inside userId folder

        await ref.putFile(file);
        downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(user.uid)
            .update({'resumeUrl': downloadUrl});

        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading resume: ${e.toString()}')),
      );
    }
  }

  Future<void> loadResume() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('userProfiles')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()!.containsKey('resumeUrl')) {
          setState(() {
            downloadUrl = doc.data()!['resumeUrl'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading resume: $e');
    }
  }



  Widget buildProfileRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }




// Helper Function for Info Row
  Widget buildInfoRow({required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.lato(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
    );
  }
  Widget buildPDFViewer() {
    if (downloadUrl == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Platform.isIOS ? CupertinoColors.white : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resume Preview',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Page ${currentPage + 1} of $totalPages',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(
            height: screenHeight * 0.6,
            child: PDF(
              enableSwipe: true,
              defaultPage: currentPage,
              onPageChanged: (int? page, int? total) {
                setState(() {
                  currentPage = page ?? 0;
                  totalPages = total ?? 0;
                });
              },
              onViewCreated: (PDFViewController controller) {
                pdfViewController = controller;
                controller.getPageCount().then((count) {
                  setState(() {
                    totalPages = count ?? 0;
                  });
                });
              },
            ).cachedFromUrl(
              downloadUrl!,
              placeholder: (progress) => Center(
                child: CircularProgressIndicator(
                  value: progress,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              errorWidget: (error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading PDF: $error',
                      style: GoogleFonts.poppins(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: currentPage > 0
                      ? () async {
                    setState(() {
                      if (currentPage > 0) {
                        currentPage--;
                      }
                    });
                    await pdfViewController?.setPage(currentPage);
                  }
                      : null,
                  color: currentPage > 0 ? Colors.green : Colors.grey,
                ),
                Text(
                  '${currentPage + 1} / $totalPages',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: currentPage < totalPages - 1
                      ? () async {
                    setState(() {
                      if (currentPage < totalPages - 1) {
                        currentPage++;
                      }
                    });
                    await pdfViewController?.setPage(currentPage);
                  }
                      : null,
                  color: currentPage < totalPages - 1 ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color labelColor,
    required Color backgroundColor,
    Color? borderColor,
    double borderWidth = 0.0,
    required BuildContext context,
  }) {
    // Get screen dimensions and orientation
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Platform.isIOS
        ? CupertinoButton(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * (isPortrait ? 0.1 : 0.15),
        vertical: screenHeight * (isPortrait ? 0.02 : 0.03),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: labelColor),
          SizedBox(width: screenWidth * 0.02),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
        : ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: labelColor),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: labelColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: labelColor,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * (isPortrait ? 0.1 : 0.15),
          vertical: screenHeight * (isPortrait ? 0.02 : 0.03),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: borderColor != null
              ? BorderSide(color: borderColor, width: borderWidth)
              : BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    orientation = MediaQuery.of(context).orientation;

    final body = SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0C2), Color(0xFF7FFFD4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.03),
            buildProfileHeader(),
            SizedBox(height: screenHeight * 0.03),
            buildPDFViewer(),
            SizedBox(height: screenHeight * 0.03),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: pickAndUploadResume,
                      icon: const Icon(
                        Icons.upload_file,
                        color: Colors.black,
                      ),
                      label: Text(
                        'Upload Resume',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (downloadUrl != null) {
                          Share.share('Here is my uploaded resume: $downloadUrl');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No resume uploaded to share.',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Share Resume',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),






            SizedBox(height: screenHeight * 0.04),
          ],
        ),
      ),
    );

    // if (Platform.isIOS) {
    //   return CupertinoPageScaffold(
    //     navigationBar: _buildPlatformSpecificAppBar() as ObstructingPreferredSizeWidget,
    //     child: body,
    //   );
    // }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildPlatformSpecificAppBar() as PreferredSizeWidget,

      body:  body,
    );
  }

}

