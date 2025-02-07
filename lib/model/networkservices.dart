import 'dart:convert';
import 'dart:io' ;


import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;




import 'cvlibraryJob.dart';
import 'jobdescription.dart';

class ApiServices {
  List<ReedResult> abcJob = [];

  Future<List<ReedResult>> getFilesApi(String title, String town) async {
    String Username = 'd9b1179f-f620-4742-a5cc-ece469c24d00';
    String Password = '';

    String basicAuth = 'Basic ${base64.encode(
          utf8.encode('$Username:$Password'),
        )}';

    //kIsWeb is used for web platforms
    if(kIsWeb){
      try {
        final String url1 =
            "https://www.reed.co.uk/api/1.0/search?keywords=$title&location=$town";

        final response = await http.get(Uri.parse(url1),
          headers: <String, String>{'authorization': basicAuth,  "Content-Type": "application/json",




          },

        );
        if (response.statusCode == 200) {
          Map<String, dynamic> json = jsonDecode(response.body);
          json['results'].forEach((element) {
            if (abcJob.length < 400000) {
              abcJob.add(ReedResult.fromJson(element));
            }
          });

          return abcJob;

        }else {
          throw Exception('Failed to load album');
        }
      } catch (e) {
        print('error is : $e');
      }
      return abcJob;


    }else{
      //mobile platform
      try {
      final String url1 =
          "https://www.reed.co.uk/api/1.0/search?keywords=$title&location=$town";
      try {
        final result = await InternetAddress.lookup(url1);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('connected');
        }
      } on SocketException catch (_) {
        print('not connected');
      }
      final response = await http.get(Uri.parse(url1),
          headers: <String, String>{'authorization': basicAuth,  "Content-Type": "application/json",

          },

      );

      //var data = jsonDecode(response.body).toList();

      //print(response.body);
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        json['results'].forEach((element) {
          if (abcJob.length < 400000) {
            abcJob.add(ReedResult.fromJson(element));
          }
        });

        return abcJob;
      } else {
        throw Exception('Failed to load album');
      }
    } catch (e) {
      print('error is : $e');
    }
    return abcJob;
    }
  }

  List<CvJobs> cvlibraryjob = [];
  bool isRefresh = false;

  int offsetNumber =
      0; //must be 0 because search using jobtitle and location might return zero or less than 25 jobs
  int totalPage = 400000;

  Future<List<CvJobs>> getCvLibraryJob(String cvtitle, String cvlocation) async {
    //for web platform
    if(kIsWeb){
      final String url =
          'https://www.cv-library.co.uk/search-jobs-json?key=zkM61g6mb,9z-byL&q=job&perpage=25&offset=$offsetNumber&title=$cvtitle&geo=$cvlocation&description_limit=400&applyurl';
      final cvResponse = await http.get(Uri.parse(url));
      //print(cvResponse.body);

      if (cvResponse.statusCode == 200) {
        //var encodecvresponse = jsonEncode(cvResponse.body);
        Map<String, dynamic> json = jsonDecode(cvResponse.body);

        //try and catch for null return forEach method

        json['jobs'].forEach((element) {
          // ignore: unnecessary_null_comparison
          if (cvlibraryjob.length < 400000) {
            cvlibraryjob.add(CvJobs.fromJson(element));
            offsetNumber + 25;
            //cvlibraryjob = <Job>[];
          }
        });

        totalPage = cvlibraryjob.length;
        return cvlibraryjob;
      } else {
        throw Exception('check network');
      }

    }else{
      //platform is mobile
    try {
      final String url =
          'https://www.cv-library.co.uk/search-jobs-json?key=zkM61g6mb,9z-byL&q=job&perpage=25&offset=$offsetNumber&title=$cvtitle&geo=$cvlocation&description_limit=4000&applyurl';
      try {
        final result = await InternetAddress.lookup(url);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('connected');
        }
      } on SocketException catch (_) {
        print('not connected');
      }
      final cvResponse = await http.get(Uri.parse(url));

     // print(cvResponse.body);

      if (cvResponse.statusCode == 200) {
        //var encodecvresponse = jsonEncode(cvResponse.body);
        Map<String, dynamic> json = jsonDecode(cvResponse.body);

        //try and catch for null return forEach method

        json['jobs'].forEach((element) {
          // ignore: unnecessary_null_comparison
          if (cvlibraryjob.length < 400000) {
            cvlibraryjob.add(CvJobs.fromJson(element));
            offsetNumber + 25;
            //cvlibraryjob = <Job>[];
          }
        });

        totalPage = cvlibraryjob.length;
        return cvlibraryjob;
      } else {
        throw Exception('check network');
      }
    } catch (e) {
      print('catched error: $e');
    }
    //return [];
    }
    return cvlibraryjob;
  }

  Future<List<String>> jobCategoriesSuggestions(String query) async {
    if (query.isEmpty) return [];

    List<String> jobTitles = [];

    try {
      // Fetch jobs from Reed API
      final reedResults = await getFilesApi(query, ""); // Pass query as title
      jobTitles.addAll(
        reedResults.map((job) => job.jobTitle ?? '').where((title) => title.isNotEmpty),
      );

      // Fetch jobs from CV Library API
      final cvResults = await getCvLibraryJob(query, ""); // Pass query as title
      jobTitles.addAll(
        cvResults.map((job) => job.hlTitle ?? '').where((title) => title.isNotEmpty),
      );

      // Remove duplicates and filter by the query
      return jobTitles
          .toSet()
          .where((title) => title.toLowerCase().contains(query.toLowerCase()))
          .take(10) // Limit to 10 suggestions
          .toList();
    } catch (e) {
      print("Error fetching job suggestions: $e");
      return [];
    }
  }




}
