import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tuned_jobs/screens/savedJobs.dart';
import 'package:tuned_jobs/screens/saved_applied.dart';

import '../provider/favouriteProvider.dart';
 // This should contain your AppliedJobsPage widget

class SavedAndAppliedJobsTab extends StatefulWidget {
  const SavedAndAppliedJobsTab({super.key});

  @override
  State<SavedAndAppliedJobsTab> createState() => _SavedAndAppliedJobsTabState();
}

class _SavedAndAppliedJobsTabState extends State<SavedAndAppliedJobsTab> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final favouritesJob = Provider.of<FavouritesJob>(context, listen: false);
   favouritesJob.initializeData();
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(

          title:  Text('My Jobs',
            style: GoogleFonts.poppins(
              textStyle:  TextStyle(color: Colors.grey[600], letterSpacing: .5, fontSize: 24, fontWeight: FontWeight.w900),
            ),
         ),
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFFFE0C2),
          elevation: 4,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.bookmark), text: 'Saved Jobs'),
              Tab(icon: Icon(Icons.check_circle), text: 'Applied Jobs'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFE0C2), // Top gradient color (peach-like)
                Color(0xFF7FFFD4), // Bottom gradient color (blue-like)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),

          child: const TabBarView(
            children: [
              SavedJobsPage(),
              AppliedJobsPage()
            ],
          ),
        ),
      ),
    );
  }
}


class ResponsiveJobCard extends StatelessWidget {
  final dynamic job;
  final bool isCvLibrary;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final bool isWideScreen;

  const ResponsiveJobCard({
    Key? key,
    required this.job,
    required this.isCvLibrary,
    required this.onDelete,
    required this.onView,
    this.isWideScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final jobTitle = isCvLibrary
        ? job.hlTitle ?? 'Job Title Not Specified'
        : job.jobTitle ?? 'Job Title Not Specified';
    final location = isCvLibrary
        ? job.location ?? 'Location not specified'
        : job.locationName ?? 'Location not specified';
    final postedDate = isCvLibrary
        ? job.posted ?? 'N/A'
        : job.date ?? 'N/A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.symmetric(
        vertical: 10,
        horizontal: isWideScreen ? 16 : 0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: TextStyle(
                          fontSize: isWideScreen ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: isWideScreen ? 16 : 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Posted on: $postedDate',
                        style: TextStyle(
                          fontSize: isWideScreen ? 14 : 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Platform.isIOS
                        ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onDelete,
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.destructiveRed,
                      ),
                    )
                        : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                    Platform.isIOS
                        ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onView,
                      child: const Icon(
                        CupertinoIcons.arrow_right,
                        color: CupertinoColors.activeBlue,
                      ),
                    )
                        : IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.teal),
                      onPressed: onView,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveJobsPage extends StatelessWidget {
  final bool isAppliedJobs;

  const ResponsiveJobsPage({
    Key? key,
    required this.isAppliedJobs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        return OrientationBuilder(
          builder: (context, orientation) {
            return isAppliedJobs
                ? AppliedJobsPage(isWideScreen: isWideScreen)
                : SavedJobsPage(isWideScreen: isWideScreen);
          },
        );
      },
    );
  }
}