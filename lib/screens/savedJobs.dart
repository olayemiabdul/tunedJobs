//
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../provider/favouriteProvider.dart';
//
// import 'jobs_details.dart';
//
//
// class SavedJobsPage extends StatelessWidget {
//   const SavedJobsPage({super.key, required bool isWideScreen});
//
//   @override
//   Widget build(BuildContext context) {
//     final favouritesJob = Provider.of<FavouritesJob>(context);
//     final savedCvJobs = favouritesJob.savedCvJobs;
//     final savedReedJobs = favouritesJob.savedReedJobs;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Saved Jobs', style: GoogleFonts.poppins(
//           textStyle: TextStyle( letterSpacing: .5),
//         ),),
//         backgroundColor: Colors.teal,
//         automaticallyImplyLeading: false,
//         elevation: 4,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFFFFE0C2), // Top gradient color (peach-like)
//               Color(0xFF7FFFD4), // Bottom gradient color (blue-like)
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: savedCvJobs.isEmpty && savedReedJobs.isEmpty
//             ? Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFFFFE0C2), // Top gradient color (peach-like)
//                 Color(0xFF7FFFD4), // Bottom gradient color (blue-like)
//               ],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//               child: Center(
//
//                         child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.bookmark_outline, size: 80, color: Colors.grey[400]),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'No saved jobs yet',
//                   style: TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Tap the heart icon on a job to save it for later.',
//                   style: TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//               ],
//                         ),
//                       ),
//             )
//             : ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: savedCvJobs.length + savedReedJobs.length,
//           itemBuilder: (context, index) {
//             if (index < savedCvJobs.length) {
//               return _buildJobCard(
//                 context,
//                 job: savedCvJobs[index],
//                 isCvLibrary: true,
//                 onDelete: () {
//                   favouritesJob.deleteSavedCvJob(savedCvJobs[index]);
//                 },
//               );
//             } else {
//               final reedIndex = index - savedCvJobs.length;
//               return _buildJobCard(
//                 context,
//                 job: savedReedJobs[reedIndex],
//                 isCvLibrary: false,
//                 onDelete: () {
//                   favouritesJob.deleteSavedReedJob(savedReedJobs[reedIndex]);
//                 },
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildJobCard(BuildContext context,
//       {required dynamic job,
//         required bool isCvLibrary,
//         required VoidCallback onDelete}) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     isCvLibrary
//                         ? job.hlTitle ?? 'Job Title Not Specified'
//                         : job.jobTitle ?? 'Job Title Not Specified',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.teal[800],
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     isCvLibrary
//                         ? job.location ?? 'Location not specified'
//                         : job.locationName ?? 'Location not specified',
//                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     isCvLibrary
//                         ? 'Posted on: ${job.posted ?? 'N/A'}'
//                         : 'Posted on: ${job.date ?? 'N/A'}',
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10),
//             Column(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: onDelete,
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.arrow_forward, color: Colors.teal),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ChangeNotifierProvider.value(
//                           value: Provider.of<FavouritesJob>(context, listen: false),
//                           child: AllJobDetailsPage(
//                             jobDetails: job,
//                             isCvLibrary: isCvLibrary,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../provider/favouriteProvider.dart';
import 'favourite tab.dart';
import 'jobs_details.dart';

class SavedJobsPage extends StatefulWidget {
  final bool isWideScreen;

  const SavedJobsPage({
    super.key,
    this.isWideScreen = false,
  });

  @override
  State<SavedJobsPage> createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    final favouritesJob = Provider.of<FavouritesJob>(context);
    final savedCvJobs = favouritesJob.savedCvJobs;
    final savedReedJobs = favouritesJob.savedReedJobs;

    final body = savedCvJobs.isEmpty && savedReedJobs.isEmpty
        ? _buildEmptyState()
        : _buildJobsList(
      context,
      savedCvJobs,
      savedReedJobs,
      favouritesJob,
      widget.isWideScreen,
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            'Saved Jobs',
            style: GoogleFonts.poppins(letterSpacing: .5),
          ),
          backgroundColor: CupertinoColors.systemTeal,
        ),
        child: _buildGradientContainer(body),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Jobs',
          style: GoogleFonts.poppins(letterSpacing: .5),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
      body: _buildGradientContainer(body),
    );
  }

  Widget _buildGradientContainer(Widget child) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFE0C2),
            Color(0xFF7FFFD4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Platform.isIOS
                ? CupertinoIcons.bookmark
                : Icons.bookmark_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved jobs yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the heart icon on a job to save it for later.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(
      BuildContext context,
      List<dynamic> savedCvJobs,
      List<dynamic> savedReedJobs,
      FavouritesJob favouritesJob,
      bool isWideScreen,
      ) {
    return SafeArea(
      child: ListView.builder(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        itemCount: savedCvJobs.length + savedReedJobs.length,
        itemBuilder: (context, index) {
          if (index < savedCvJobs.length) {
            return ResponsiveJobCard(
              job: savedCvJobs[index],
              isCvLibrary: true,
              isWideScreen: isWideScreen,
              onDelete: () {
                favouritesJob.deleteSavedCvJob(savedCvJobs[index]);
              },
              onView: () => _navigateToDetails(
                context,
                savedCvJobs[index],
                true,
                favouritesJob,
              ),
            );
          } else {
            final reedIndex = index - savedCvJobs.length;
            return ResponsiveJobCard(
              job: savedReedJobs[reedIndex],
              isCvLibrary: false,
              isWideScreen: isWideScreen,
              onDelete: () {
                favouritesJob.deleteSavedReedJob(savedReedJobs[reedIndex]);
              },
              onView: () => _navigateToDetails(
                context,
                savedReedJobs[reedIndex],
                false,
                favouritesJob,
              ),
            );
          }
        },
      ),
    );
  }

  void _navigateToDetails(
      BuildContext context,
      dynamic job,
      bool isCvLibrary,
      FavouritesJob favouritesJob,
      ) {
    Navigator.push(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: favouritesJob,
          child: AllJobDetailsPage(
            jobDetails: job,
            isCvLibrary: isCvLibrary,
          ),
        ),
      )
          : MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: favouritesJob,
          child: AllJobDetailsPage(
            jobDetails: job,
            isCvLibrary: isCvLibrary,
          ),
        ),
      ),
    );
  }
}
