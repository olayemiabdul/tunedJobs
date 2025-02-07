import 'dart:io';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';



import '../model/cvlibraryJob.dart';
import '../model/jobdescription.dart';
import '../model/networkservices.dart';
import '../provider/favouriteProvider.dart';
import 'jobs_details.dart';

class AllJobSearchScreen extends StatefulWidget {
  const AllJobSearchScreen({super.key});

  @override
  State<AllJobSearchScreen> createState() => _AllJobSearchScreenState();
}

class _AllJobSearchScreenState extends State<AllJobSearchScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final jobTitleController = TextEditingController();
  final locationController = TextEditingController();
  final ApiServices jobApi = ApiServices();
  final RefreshController refreshController =
  RefreshController(initialRefresh: false);

  List<CvJobs> cvLibraryJobs = [];
  List<ReedResult> reedJobs = [];
  List<CvJobs> filteredCvLibraryJobs = [];
  List<String> searchSuggestions = [];
  List<ReedResult> filteredReedJobs = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  bool isInitialized = false;
  bool showOverlay = false;
  int totalJobs = 0;
  late double screenWidth;
  late double screenHeight;
  late Orientation orientation;

  @override
  void initState() {
    super.initState();
    getInitialJobs();

    //check focus node for the textfield cursor

    jobTitleController.addListener(() async {
      final query = jobTitleController.text.trim();
      if (query.isNotEmpty) {
        showOverlay = true;
        isLoading = true;
        setState(() {});
        searchSuggestions = await jobApi.jobCategoriesSuggestions(query);
        isLoading = false;
      } else {
        showOverlay = false;
        searchSuggestions = [];
      }
      setState(() {});
    });
  }



  @override
  void dispose() {
    jobTitleController.dispose();
    locationController.dispose();
    refreshController.dispose();
    super.dispose();
  }
  Widget buildSearchOverlay() {
    if (!showOverlay) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.3), // Semi-transparent background
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: jobTitleController,
                      decoration: const InputDecoration(
                        hintText: "Search jobs...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          showOverlay = false;
                          searchSuggestions.clear();
                        } else {
                          showOverlay = true;
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      jobTitleController.clear();
                      showOverlay = false;
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: searchSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = searchSuggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.lightbulb_outline, color: Colors.grey),
                      title: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      onTap: () async {
                        // Set the text field to the selected suggestion
                        jobTitleController.text = suggestion;

                        // Hide overlay
                        showOverlay = true;
                        setState(() {});


                        // Trigger the search with the selected suggestion
                        await searchJobs(suggestion, locationController.text);

                        // Update the UI to show results
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget buildSearchField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required VoidCallback onSubmitted,
  }) {


    return TextField(
      controller: controller,
      onSubmitted: (_) => onSubmitted(),
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: placeholder,
        hintStyle: const TextStyle(color: Colors.grey),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
    );
  }

  Widget buildJobCard({
    required Widget content,
    required double width,
  }) {
    if (Platform.isIOS) {
      return Container(
        width: width,


        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      );
    }

    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 80,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: content,
        ),
      ),

    );
  }
//passing orientation and screenwidth for responsive
  Widget buildCvJobCard(FavouritesJob favouritesJob, CvJobs job, Orientation orientation, double screenWidth) {
    final provider = Provider.of<FavouritesJob>(context, listen: false);
    final cardWidth = orientation == Orientation.landscape
        ? screenWidth * 0.9
        : screenWidth * 0.45;

    final content = ListTile(
      contentPadding: EdgeInsets.all(screenWidth * 0.04),
      title: Text(
        job.hlTitle ?? 'Job Title Not Specified',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.location ?? 'Location not specified'),
          Text(job.salary ?? 'Salary not specified'),
          Text('Posted: ${job.posted!.hour} ago'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: buildActionButtons(
          isFavorite: favouritesJob.cvlikedjobs(job),
          onFavoritePressed: () {
            setState(() {
              favouritesJob.cvtoggleFavourite(job);
              favouritesJob.saveCvJob(job);
            });
          },
          onSharePressed: () {
            Share.share("https://www.cv-library.co.uk${job.url}");
          },
        ),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: provider,
            child: AllJobDetailsPage(
              jobDetails: job,
              isCvLibrary: true,
            ),
          ),
        ),
      ),
    );

    return buildJobCard(content: content, width: cardWidth);
  }
  Widget buildReedJobCard(FavouritesJob favouritesJob, ReedResult job, Orientation orientation, double screenWidth) {
    final provider = Provider.of<FavouritesJob>(context, listen: false);
    final cardWidth = orientation == Orientation.portrait
        ? screenWidth * 0.9
        : screenWidth * 0.45;

    final content = ListTile(
      contentPadding: EdgeInsets.all(screenWidth * 0.04),
      title: Text(
        job.jobTitle ?? 'Job Title Not Specified',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            job.employerName ?? 'Employer not specified',
            //style: TextStyle(fontSize: screenWidth * 0.035),
          ),
          Text(
            job.locationName ?? 'Location not specified',
            //style: TextStyle(fontSize: screenWidth * 0.035),
          ),
          Text(
            'Posted: ${job.date.toString()}',
            //style: TextStyle(fontSize: screenWidth * 0.035),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: buildActionButtons(
          isFavorite: favouritesJob.likedJobs(job),
          onFavoritePressed: () {
            setState(() {
              favouritesJob.toggleFavourite(job);
              favouritesJob.saveReedJob(job);
            });
          },
          onSharePressed: () {
            Share.share(job.jobUrl.toString());
          },
        ),
      ),
      onTap: () =>  Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: provider,
            child: AllJobDetailsPage(
              jobDetails: job,
              isCvLibrary: false,
            ),
          ),
        ),
      ),
    );

    return buildJobCard(content: content, width: cardWidth);
  }

  List<Widget> buildActionButtons({
    required bool isFavorite,
    required VoidCallback onFavoritePressed,
    required VoidCallback onSharePressed,
  }) {
    final iconSize = screenWidth * 0.06;

    if (Platform.isIOS) {
      return [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onFavoritePressed,
          child: Icon(
            isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            color: isFavorite ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
            size: iconSize,
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onSharePressed,
          child: Icon(
            CupertinoIcons.share,
            color: CupertinoColors.activeBlue,
            size: iconSize,
          ),
        ),
      ];
    }

    return [
      IconButton(
        icon: Icon(
          isFavorite ? FontAwesomeIcons.heart : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.grey,
          size: iconSize,
        ),
        onPressed: onFavoritePressed,
      ),
      IconButton(
        icon: Icon(
          FontAwesomeIcons.share,
          color: Colors.teal,
          size: iconSize,
        ),
        onPressed: onSharePressed,
      ),
    ];
  }

  Widget buildJobList() {
    if (isLoading) {
      return Center(
        child: Platform.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              style: TextStyle(
                color: Platform.isIOS
                    ? CupertinoColors.systemRed
                    : Colors.red,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Platform.isIOS
                ? CupertinoButton(
              onPressed: () => searchJobs(
                jobTitleController.text,
                locationController.text,
              ),
              child: const Text('Retry'),
            )
                : ElevatedButton(
              onPressed: () => searchJobs(
                jobTitleController.text,
                locationController.text,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredCvLibraryJobs.isEmpty && filteredReedJobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'No jobs found. Check your search or remove any extra spaces. or Press enter',
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
        ),

      );
    }

    return SmartRefresher(
      controller: refreshController,
      enablePullDown: true,
      enablePullUp: false,
      onRefresh: () {
        searchJobs(jobTitleController.text, locationController.text);
      },
      child: orientation == Orientation.portrait
          ? ListView(
        children: buildJobCards(),
      )
          : GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2,
        children: buildJobCards(),
      ),
    );
  }
  List<Widget> buildJobCards() {
    final List<Widget> cards = [];
    final favouritesJob = Provider.of<FavouritesJob>(context, listen: false);
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = MediaQuery.of(context).size.width;

    for (var job in filteredCvLibraryJobs) {
      cards.add(buildCvJobCard(favouritesJob, job, orientation,screenWidth));
    }
    for (var job in filteredReedJobs) {
      cards.add(buildReedJobCard(favouritesJob, job, orientation,screenWidth));
    }

    return cards;
  }




  Widget buildSearchFields() {
    return Container(
      width: screenWidth,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Row(
        children: [
          Expanded(
            child: buildSearchField(
              controller: jobTitleController,
              placeholder: 'Job Title',
              icon: Platform.isIOS
                  ? CupertinoIcons.briefcase_fill
                  : Icons.work_outline,
              onSubmitted: () {
                showOverlay = false;
                searchJobs(
                  jobTitleController.text,
                  locationController.text,
                );
              },
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: buildSearchField(
              controller: locationController,
              placeholder: 'Location',
              icon: Platform.isIOS
                  ? CupertinoIcons.location
                  : Icons.location_on_outlined,
              onSubmitted: () {
                searchJobs(
                  jobTitleController.text,
                  locationController.text,
                );


              }
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget buildSearchAppBar() {


    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0C2), Color(0xFF7FFFD4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      title: buildSearchFields(),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.05),
        child: buildTotalJobsCounter(),
      ),
    );
  }

  Widget buildTotalJobsCounter() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Platform.isIOS ? CupertinoIcons.briefcase : Icons.work,
            size: screenWidth * 0.05,
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            'Total Jobs: ${cvLibraryJobs.length + reedJobs.length}',
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
        ],
      ),
    );
  }


  Future<void> getInitialJobs() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final cvJobs = await jobApi.getCvLibraryJob('', '');
      final reedJobResults = await jobApi.getFilesApi('', '');

      if (mounted) {
        setState(() {
          cvLibraryJobs = cvJobs;
          reedJobs = reedJobResults;
          filteredCvLibraryJobs = cvJobs;
          filteredReedJobs = reedJobResults;
          totalJobs = cvLibraryJobs.length + reedJobs.length;
          isInitialized = true;
          isLoading = false;
        });
        refreshController.refreshCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = 'Failed to load jobs. Please try again.';
          isLoading = false;
        });
        refreshController.refreshFailed();
      }
      debugPrint('Error fetching initial jobs: $e');
    }
  }

  void filterJobs() {
    String jobTitle = jobTitleController.text.toLowerCase();
    String location = locationController.text.toLowerCase();

    if (jobTitle.isEmpty && location.isEmpty) {
      setState(() {
        filteredCvLibraryJobs = cvLibraryJobs;
        filteredReedJobs = reedJobs;
      });
    } else {
      setState(() {
        filteredCvLibraryJobs = cvLibraryJobs
            .where((job) =>
        (job.hlTitle ?? '').toLowerCase().contains(jobTitle) &&
            (job.location ?? '').toLowerCase().contains(location))
            .toList();
        filteredReedJobs = reedJobs
            .where((job) =>
        (job.jobTitle ?? '').toLowerCase().contains(jobTitle) &&
            (job.locationName ?? '').toLowerCase().contains(location))
            .toList();
      });
    }
  }

  Future<void> searchJobs(String jobTitle, String location) async {
    if (isLoading) return;

    // If no user input, load initial jobs
    if (jobTitle.trim().isEmpty && location.trim().isEmpty) {
      getInitialJobs();
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      // Fetch filtered jobs based on user inputs
      final cvJobs = await jobApi.getCvLibraryJob(jobTitle, location);
      final reedJobResults = await jobApi.getFilesApi(jobTitle, location);

      if (mounted) {
        setState(() {
          cvLibraryJobs = cvJobs;
          reedJobs = reedJobResults;
          totalJobs = cvLibraryJobs.length + reedJobResults.length;
          isLoading = false;
        });
        filterJobs(); // Apply filtering after fetching
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = 'Search failed. Please try again.';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      debugPrint('Error searching jobs: $e');
    }
  }






  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF7FFFD4),
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    orientation = MediaQuery.of(context).orientation;





    return SafeArea(
      child: Scaffold(
        appBar: buildSearchAppBar(),
        body: Stack(
          children: [
            Container(
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
              child: Column(
                children: [
                  Expanded(
                    child: buildJobList(),
                  ),
                ],
              ),
            ),
            buildSearchOverlay(),
          ],
        ),
      ),
    );
  }
}
