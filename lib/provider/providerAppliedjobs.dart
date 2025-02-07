// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:ukjobsearch/model/jobdescription.dart';
// import 'package:ukjobsearch/model/networkservices.dart';
// import 'package:ukjobsearch/provider/favouriteProvider.dart';
//
//
// class AppliedJob extends StatefulWidget {
//   const AppliedJob({super.key});
//
//   @override
//   State<AppliedJob> createState() => _AppliedJobState();
// }
//
// class _AppliedJobState extends State<AppliedJob> {
//   ApiServices jobApi = ApiServices();
//
//   final jobTitleController = TextEditingController();
//
//   final cityController = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.black,
//           title: const Text('saved Jobs'),
//         ),
//         body: SizedBox(
//           height: MediaQuery.of(context).size.height,
//           width: MediaQuery.of(context).size.width,
//           child: FutureBuilder(
//             future: jobApi.getFilesApi(
//                 jobTitleController.text, cityController.text),
//             builder:
//                 (BuildContext context, AsyncSnapshot<List<Result>> snapshot) {
//               if (snapshot.hasData) {
//                 // List<Result> olayemi = snapshot.data!;
//                 final provider = Provider.of<FavouritesJob>(context);
//                 //to get the job send to save page, use
//                 final olayemi = provider.reedJobs;
//
//                 return ListView.builder(
//                     scrollDirection: Axis.vertical,
//                     shrinkWrap: true,
//                     itemCount: olayemi.length,
//                     itemBuilder: (context, index) {
//                       //var employerProfile = olayemi[index].employerProfileId;
//                       return Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Container(
//                           height: 170,
//                           width: 120,
//                           decoration: BoxDecoration(
//                             borderRadius: const BorderRadius.only(
//                                 topLeft: Radius.circular(15),
//                                 topRight: Radius.circular(15),
//                                 bottomLeft: Radius.circular(15),
//                                 bottomRight: Radius.circular(15)),
//                             color: Colors.green,
//                             border: Border.all(
//                               color: Colors.white,
//                               width: 1,
//                             ),
//                           ),
//                           child: ListTile(
//                             title: Column(
//                               children: [
//                                 Align(
//                                   alignment: Alignment.topLeft,
//                                   child: Text(
//                                     olayemi[index].jobTitle.toString(),
//                                     style: const TextStyle(
//                                         fontFamily: 'Poppins-ExtraBold',
//                                         fontSize: 20,
//                                         color: Colors.white),
//                                   ),
//                                 ),
//                                 const SizedBox(
//                                   height: 5,
//                                 ),
//                                 Align(
//                                   alignment: Alignment.topLeft,
//                                   child: Text(
//                                     olayemi[index].employerName.toString(),
//                                   ),
//                                 ),
//                                 const SizedBox(
//                                   height: 5,
//                                 ),
//                                 Align(
//                                   alignment: Alignment.topLeft,
//                                   child: Text(olayemi[index]
//                                       .locationName
//                                       .toString()),
//                                 ),
//                                 const SizedBox(
//                                   height: 5,
//                                 ),
//                                 Align(
//                                   alignment: Alignment.topLeft,
//                                   child: Text(
//                                       "posted on ${olayemi[index].date.toString()}"),
//                                 ),
//                                 const SizedBox(
//                                   height: 5,
//                                 ),
//                               ],
//                             ),
//                             //trailing:employerProfile !=null?Image.network(olayemi[index].employerProfileId):Image.asset('assets/images/emp.png'),
//                             trailing: IconButton(
//                                 onPressed: () {
//                                   provider
//                                       .toggleFavourite(jobApi.abcJob[index]);
//                                 },
//                                 icon:
//                                     provider.likedJobs(jobApi.abcJob[index])
//                                         ? const Icon(
//                                             Icons.favorite,
//                                             color: Colors.red,
//                                           )
//                                         : const Icon(Icons.favorite_border)),
//                             // onTap: () {
//                             //   Navigator.push(
//                             //     context,
//                             //     MaterialPageRoute(
//                             //       builder: ((context) {
//                             //         return DescriptionPagem(
//                             //           jobdetailsm: jobApi.abcJob[index],
//                             //         );
//                             //       }),
//                             //     ),
//                             //   );
//                             // },
//                           ),
//                         ),
//                       );
//                     });
//               } else {
//                 return const CircularProgressIndicator();
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }