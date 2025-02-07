class ReedJob {
    ReedJob({
        required this.results,
    });

    final List<ReedResult> results;

    factory ReedJob.fromJson(Map<String, dynamic> json){ 
        return ReedJob(
            results: json["results"] == null ? [] : List<ReedResult>.from(json["results"]!.map((x) => ReedResult.fromJson(x))),
        );
    }

   

}

class ReedResult {
    ReedResult({
        required this.jobId,
        required this.employerId,
        required this.employerName,
        required this.employerProfileId,
        required this.employerProfileName,
        required this.jobTitle,
        required this.locationName,
        required this.minimumSalary,
        required this.maximumSalary,
        required this.currency,
        required this.expirationDate,
        required this.date,
        required this.jobDescription,
        required this.applications,
        required this.jobUrl,
    });

    final int? jobId;
    final int? employerId;
    final String? employerName;
    final dynamic employerProfileId;
    final dynamic employerProfileName;
    final String? jobTitle;
    final String? locationName;
    final double? minimumSalary;
    final double? maximumSalary;
    final String? currency;
    final String? expirationDate;
    final String? date;
    final String? jobDescription;
    final int? applications;
    final String? jobUrl;

    factory ReedResult.fromJson(Map<String, dynamic> json){
        return ReedResult(
            jobId: json["jobId"],
            employerId: json["employerId"],
            employerName: json["employerName"],
            employerProfileId: json["employerProfileId"],
            employerProfileName: json["employerProfileName"],
            jobTitle: json["jobTitle"],
            locationName: json["locationName"],
            minimumSalary: json["minimumSalary"],
            maximumSalary: json["maximumSalary"],
            currency: json["currency"],
            expirationDate: json["expirationDate"],
            date: json["date"],
            jobDescription: json["jobDescription"],
            applications: json["applications"],
            jobUrl: json["jobUrl"],
        );
    }
    Map<String, dynamic> toJson() {
        return {
            'jobId': jobId,
            'employerId': employerId,
            'employerName': employerName,
            'employerProfileId': employerProfileId,
            'employerProfileName': employerProfileName,
            'jobTitle': jobTitle,
            'locationName': locationName,
            'minimumSalary': minimumSalary,
            'maximumSalary': maximumSalary,
            'currency': currency,
            'expirationDate': expirationDate,
            'date': date,
            'jobDescription': jobDescription,
            'applications': applications,
            'jobUrl': jobUrl,
        };
    }

}


  