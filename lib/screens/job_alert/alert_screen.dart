import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;


import 'email_services.dart';
import 'job_alert_class.dart';


class JobAlertPage extends StatefulWidget {
  const JobAlertPage({super.key});

  @override
  State<JobAlertPage> createState() => _JobAlertPageState();
}

class _JobAlertPageState extends State<JobAlertPage> {
  final formKey = GlobalKey<FormState>();
  final jobTitleController = TextEditingController();
  final locationController = TextEditingController();
  bool emailNotification = false;
  bool appNotification = true;
  String frequency = 'daily';
  final user = FirebaseAuth.instance.currentUser;
  bool showList = true;
  final alertId = FirebaseFirestore.instance.collection('jobAlerts').doc().id;
  String? currentAlertId;

  final notificationService = NotificationService();

  @override
  void dispose() {
    jobTitleController.dispose();
    locationController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    notificationService.initialize();
  }
  Future<void> saveJobAlert() async {
    if (formKey.currentState!.validate() && user != null) {
      try {
        final newAlertId = FirebaseFirestore.instance.collection('jobAlerts').doc().id;

        // Get current user's email
        final userEmail = FirebaseAuth.instance.currentUser?.email;
        if (userEmail == null) {
          throw Exception('User must have an email to create alerts');
        }

        final jobAlert = JobAlert(
          id: newAlertId,
          userId: user!.uid,
          userEmail: userEmail,  // Make sure this is included
          jobTitle: jobTitleController.text.trim(),
          location: locationController.text.trim(),
          emailNotification: emailNotification,
          appNotification: appNotification,
          frequency: frequency,
        );

        await FirebaseFirestore.instance
            .collection('jobAlerts')
            .doc(newAlertId)
            .set(jobAlert.toMap());

        setState(() {
          currentAlertId = newAlertId;
          showList = true; // Redirect to the list view
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job alert created successfully')),
          );
        }
        jobTitleController.clear();
        locationController.clear();
        emailNotification = false;
        appNotification = true;
      } catch (e) {
        debugPrint('Error creating job alert: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating job alert: $e')),
          );
        }
      }
    }
  }


  Widget buildJobAlertForm() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: jobTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a job title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter a location';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Email Notifications'),
                  value: emailNotification,
                  onChanged: (bool value) async {
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to update notification preferences'),
                        ),
                      );
                      return;
                    }

                    // Only attempt to update if we have a valid alert ID
                    if (currentAlertId != null) {
                      try {
                        await notificationService.updateNotificationPreferences(
                          alertId: currentAlertId!,
                          userId: user!.uid,
                          emailEnabled: value,
                          appEnabled: appNotification,
                        );

                        setState(() {
                          emailNotification = value;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value
                                  ? 'Email notifications enabled'
                                  : 'Email notifications disabled'
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update preferences: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    } else {
                      // If no alert exists yet, just update the state
                      setState(() {
                        emailNotification = value;
                      });
                    }
                  },
                ),

                SwitchListTile(
                  title: const Text('App Notifications'),
                  value: appNotification,
                  onChanged: (bool value) async {
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to update notification preferences'),
                        ),
                      );
                      return;
                    }

                    // Only attempt to update if we have a valid alert ID
                    if (currentAlertId != null) {
                      try {
                        await notificationService.updateNotificationPreferences(
                          alertId: currentAlertId!,
                          userId: user!.uid,
                          emailEnabled: emailNotification,
                          appEnabled: value,
                        );

                        setState(() {
                          appNotification = value;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value
                                  ? 'App notifications enabled'
                                  : 'App notifications disabled'
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update preferences: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    } else {
                      // If no alert exists yet, just update the state
                      setState(() {
                        appNotification = value;
                      });
                    }
                  },
                ),



                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (){

                           setState(() {
                             saveJobAlert();
                           });


                        },
                        child: const Text('Create Job Alert'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildJobAlertList() {
    if (user == null) {
      return const Center(
        child: Text(
          'Please log in to view job alerts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobAlerts')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final alerts = snapshot.data?.docs ?? [];

        if (alerts.isEmpty) {
          return const Center(
            child: Text(
              'No job alerts created yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index].data() as Map<String, dynamic>;
              final alertId = alerts[index].id;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job title
                      Text(
                        alert['jobTitle'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('jobAlerts')
                                    .doc(alertId)
                                    .delete();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Job alert deleted successfully'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error deleting job alert: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              alert['location'] ?? 'Unknown location',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Notification preferences
                      Wrap(
                        spacing: 8,
                        children: [
                          if (alert['emailNotification'] ?? false)
                            Chip(
                              label: const Text('Email Notification'),
                              backgroundColor: Colors.blue[50],
                              avatar: const Icon(
                                Icons.email,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                          if (alert['appNotification'] ?? false)
                            Chip(
                              label: const Text('App Notification'),
                              backgroundColor: Colors.green[50],
                              avatar: const Icon(
                                Icons.notifications,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ElevatedButton(
                      //   onPressed: ()async{
                      //     var res=await http.get(Uri.parse('https://sendjobalerts-js56qdzanq-uc.a.run.app'));
                      //     print(res.body);
                      //   },
                      //   child: Text('Send Mail'),
                      // ),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Frequency: ${alert['frequency'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('jobAlerts')
                                  .doc(alerts[index].id)
                                  .delete();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF7FFFD4), // Your desired color
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Scaffold(

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE0C2),
        title: Text(showList ? 'Job Alerts' : 'Create Job Alert'),
        actions: [
          if (showList)
           TextButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  showList = false;
                });
              }, label:const Text('New Alert') ,
            )
        ],
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
          child: showList ? buildJobAlertList() : buildJobAlertForm()),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// class HomePag extends StatelessWidget {
//   const HomePag({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Firebase Cloud Function"),),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: ()async{
//             var res=await http.get(Uri.parse('https://sendmail-js56qdzanq-uc.a.run.app?dest=olayemi.abdullahi'));
//             print(res.body);
//           },
//           child: Text('Send Mail'),
//         ),
//       ),
//     );
//   }
// }