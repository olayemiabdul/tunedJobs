import 'dart:io';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tuned_jobs/model/networkservices.dart';


import '../model/cvlibraryJob.dart';
import '../model/jobdescription.dart';

import '../screens/jobs_details.dart';
import 'favouriteProvider.dart';




class AllJobSearchScreen extends StatefulWidget {
  const AllJobSearchScreen({Key? key}) : super(key: key);

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
  List<ReedResult> filteredReedJobs = [];
  bool isLoading = false;
  bool hasError = false;
  String errorMessage = '';
  bool isInitialized = false;
  int totalJobs = 0;
  late double screenWidth;
  late double screenHeight;
  late Orientation orientation;
  List<String> suggestions = [];
  ApiServices apiServices = ApiServices();

  bool showSuggestions = false;
  bool isLoadingSuggestions = false;

  bool isSearchActive = false;
  final FocusNode jobTitleFocusNode = FocusNode();
  final FocusNode locationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    getInitialJobs();
    jobTitleController.addListener(() {
      filterJobs();
    });
    locationController.addListener(() {
      filterJobs();
    });

    jobTitleFocusNode.addListener(() {
      if (jobTitleFocusNode.hasFocus) {
        setState(() {
          isSearchActive = true;
        });
      }
    });
  }

  @override
  void dispose() {
    jobTitleFocusNode.dispose();
    locationFocusNode.dispose();
    jobTitleController.dispose();
    locationController.dispose();
    refreshController.dispose();
    super.dispose();
  }


  Future<void> onJobTitleChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestions.clear();
        showSuggestions = false;
        isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final newSuggestions = await apiServices.jobCategoriesSuggestions(query);
      if (mounted) {
        setState(() {
          suggestions = newSuggestions;
          showSuggestions = suggestions.isNotEmpty;
          isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      if (mounted) {
        setState(() {
          suggestions.clear();
          showSuggestions = false;
          isLoadingSuggestions = false;
        });
      }
    }
  }


  Widget buildSearchField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required VoidCallback onSubmitted,
    required void Function(String text) onChanged,
    FocusNode? focusNode,
  }) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        prefix: Icon(icon, color: CupertinoColors.systemGrey),
        onSubmitted: (_) => onSubmitted(),
        onChanged: onChanged,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      );
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: (_) => onSubmitted(),
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: placeholder,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
    );
  }

  Widget buildSuggestionsDropdown() {
    if (!showSuggestions && !isLoadingSuggestions) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.3,
      ),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoadingSuggestions
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Platform.isIOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        ),
      )
          : ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  jobTitleController.text = suggestions[index];
                  showSuggestions = false;
                  suggestions.clear();
                });
                jobTitleFocusNode.unfocus();
                searchJobs(jobTitleController.text, locationController.text);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  suggestions[index],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget buildSearchOverlay() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Back and search row
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                        color: Colors.black87,
                      ),
                      onPressed: () {
                        setState(() {
                          isSearchActive = false;
                          jobTitleFocusNode.unfocus();
                          locationFocusNode.unfocus();
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          buildSearchField(
                            controller: jobTitleController,
                            focusNode: jobTitleFocusNode,
                            placeholder: 'Search job titles...',
                            icon: Platform.isIOS ? CupertinoIcons.search : Icons.search,
                            onSubmitted: () {
                              setState(() {
                                isSearchActive = false;
                              });
                              searchJobs(jobTitleController.text, locationController.text);
                            },
                            onChanged: (text) async {
                              if (text.isNotEmpty) {
                                await onJobTitleChanged(text);
                              } else {
                                setState(() {
                                  suggestions.clear();
                                });
                              }
                            },
                          ),
                          SizedBox(height: 8),
                          buildSearchField(
                            controller: locationController,
                            focusNode: locationFocusNode,
                            placeholder: 'Location...',
                            icon: Platform.isIOS ? CupertinoIcons.location : Icons.location_on_outlined,
                            onSubmitted: () {
                              setState(() {
                                isSearchActive = false;
                              });
                              searchJobs(jobTitleController.text, locationController.text);
                            },
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Suggestions List
          Expanded(
            child: suggestions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Platform.isIOS ? CupertinoIcons.search : Icons.search,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Start typing to search jobs...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(
                    Platform.isIOS ? CupertinoIcons.briefcase : Icons.work_outline,
                    color: Colors.grey[600],
                  ),
                  title: Text(
                    suggestions[index],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    Platform.isIOS ? CupertinoIcons.forward : Icons.arrow_forward,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    setState(() {
                      jobTitleController.text = suggestions[index];
                      isSearchActive = false;
                      suggestions.clear();
                    });
                    searchJobs(jobTitleController.text, locationController.text);
                  },
                );
              },
            ),
          ),
        ],
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
        style: TextStyle(
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

  PreferredSizeWidget buildSearchAppBar() {
    if (Platform.isIOS) {
      return CupertinoNavigationBar(
        middle: buildSearchFields(),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.9),
      );
    }

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






  Widget buildSearchFields() {
    return Container(
      width: screenWidth,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: buildSearchField(
                  controller: jobTitleController,
                  focusNode: jobTitleFocusNode,
                  placeholder: 'Job Title',
                  icon: Platform.isIOS ? CupertinoIcons.briefcase : Icons.work_outline,
                  onSubmitted: () => searchJobs(
                    jobTitleController.text,
                    locationController.text,
                  ),
                  onChanged: (text) async {
                    if (text.isNotEmpty) {
                      await onJobTitleChanged(text);
                    } else {
                      setState(() {
                        suggestions.clear();
                        showSuggestions = false;
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: buildSearchField(
                  controller: locationController,
                  placeholder: 'Location',
                  icon: Platform.isIOS ? CupertinoIcons.location : Icons.location_on_outlined,
                  onSubmitted: () => searchJobs(
                    jobTitleController.text,
                    locationController.text,
                  ),
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          buildSuggestionsDropdown(),
        ],
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
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    orientation = MediaQuery.of(context).orientation;

    return Platform.isIOS
        ? CupertinoPageScaffold(
      navigationBar: buildSearchAppBar() as ObstructingPreferredSizeWidget,
      child: Stack(
        children: [
          SafeArea(
            child: buildJobList(),
          ),
          if (isSearchActive)
            Positioned.fill(
              child: buildSearchOverlay(),
            ),
        ],
      ),
    )
        : Scaffold(
      appBar: buildSearchAppBar(),
      body: Stack(
        children: [
          Container(
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
            child: buildJobList(),
          ),
          if (isSearchActive)
            Positioned.fill(
              child: buildSearchOverlay(),
            ),
        ],
      ),
    );
  }}
