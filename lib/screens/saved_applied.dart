// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../provider/favouriteProvider.dart';
// import 'jobs_details.dart';
//
// class AppliedJobsPage extends StatelessWidget {
//   const AppliedJobsPage({Key? key, required bool isWideScreen}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final favouritesJob = Provider.of<FavouritesJob>(context);
//     final appliedCvJobs = favouritesJob.appliedCvJobs;
//     final appliedReedJobs = favouritesJob.appliedReedJobs;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Applied Jobs'),
//         backgroundColor: Colors.teal,
//         elevation: 4,
//       ),
//       body: appliedCvJobs.isEmpty && appliedReedJobs.isEmpty
//           ? Container(
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
//             child: Center(
//                     child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
//               const SizedBox(height: 16),
//               const Text(
//                 'No applied jobs yet',
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Apply to a job to track it here.',
//                 style: TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//             ],
//                     ),
//                   ),
//           )
//           : Container(
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
//             child: ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: appliedCvJobs.length + appliedReedJobs.length,
//                     itemBuilder: (context, index) {
//             if (index < appliedCvJobs.length) {
//               return _buildJobCard(context, job: appliedCvJobs[index], isCvLibrary: true);
//             } else {
//               final reedIndex = index - appliedCvJobs.length;
//               return _buildJobCard(context, job: appliedReedJobs[reedIndex], isCvLibrary: false);
//             }
//                     },
//                   ),
//           ),
//     );
//   }
//
//   Widget _buildJobCard(BuildContext context, {required dynamic job, required bool isCvLibrary}) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       child: ListTile(
//         title: Text(isCvLibrary ? job.hlTitle ?? 'Unknown Title' : job.jobTitle ?? 'Unknown Title'),
//         subtitle: Text(isCvLibrary ? job.location ?? 'Unknown Location' : job.locationName ?? 'Unknown Location'),
//         trailing: const Icon(Icons.arrow_forward, color: Colors.teal),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AllJobDetailsPage(
//                 jobDetails: job,
//                 isCvLibrary: isCvLibrary,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/favouriteProvider.dart';
import 'favourite tab.dart';
import 'jobs_details.dart';

class AppliedJobsPage extends StatelessWidget {
  final bool isWideScreen;

  const AppliedJobsPage({
    Key? key,
    this.isWideScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favouritesJob = Provider.of<FavouritesJob>(context);
    final appliedCvJobs = favouritesJob.appliedCvJobs;
    final appliedReedJobs = favouritesJob.appliedReedJobs;

    final body = appliedCvJobs.isEmpty && appliedReedJobs.isEmpty
        ? _buildEmptyState()
        : _buildJobsList(
      context,
      appliedCvJobs,
      appliedReedJobs,
      favouritesJob,
      isWideScreen,
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Applied Jobs'),
          backgroundColor: CupertinoColors.systemTeal,
        ),
        child: _buildGradientContainer(body),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applied Jobs'),
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
                ? CupertinoIcons.checkmark_circle
                : Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No applied jobs yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Apply to a job to track it here.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(
      BuildContext context,
      List<dynamic> appliedCvJobs,
      List<dynamic> appliedReedJobs,
      FavouritesJob favouritesJob,
      bool isWideScreen,
      ) {
    return SafeArea(
      child: ListView.builder(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        itemCount: appliedCvJobs.length + appliedReedJobs.length,
        itemBuilder: (context, index) {
          if (index < appliedCvJobs.length) {
            return ResponsiveJobCard(
              job: appliedCvJobs[index],
              isCvLibrary: true,
              isWideScreen: isWideScreen,
              onDelete: () {
                favouritesJob.deleteAppliedCvJob(appliedCvJobs[index]);
              },
              onView: () => _navigateToDetails(
                context,
                appliedCvJobs[index],
                true,
                favouritesJob,
              ),
            );
          } else {
            final reedIndex = index - appliedCvJobs.length;
            return ResponsiveJobCard(
              job: appliedReedJobs[reedIndex],
              isCvLibrary: false,
              isWideScreen: isWideScreen,
              onDelete: () {
                favouritesJob.deleteAppliedReedJob(appliedReedJobs[reedIndex]);
              },
              onView: () => _navigateToDetails(
                context,
                appliedReedJobs[reedIndex],
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