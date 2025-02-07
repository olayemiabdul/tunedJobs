class CvLibraryJob {
    CvLibraryJob({
        required this.totalEntries,
        required this.jobs,
    });

    final int? totalEntries;
    final List<CvJobs> jobs;

    factory CvLibraryJob.fromJson(Map<String, dynamic> json){
        return CvLibraryJob(
            totalEntries: json["total_entries"],
            jobs: json["jobs"] == null ? [] : List<CvJobs>.from(json["jobs"]!.map((x) => CvJobs.fromJson(x))),
        );
    }

    Map<String, dynamic> toJson() => {
        "total_entries": totalEntries,
        "jobs": jobs.map((x) => x.toJson()).toList(),
    };

}

class CvJobs {
    CvJobs({
        required this.agency,
        required this.location,
        required this.hlTitle,
        required this.logo,
        required this.description,
        required this.url,
        required this.salary,
        required this.applications,
        required this.title,
        required this.id,
        required this.posted,
        required this.type,
    });

    final Agency? agency;
    final String? location;
    final String? hlTitle;
    final String? logo;
    final String? description;
    final String? url;
    final String? salary;
    final String? applications;
    final String? title;
    final int? id;
    final DateTime? posted;
    final List<String> type;

    factory CvJobs.fromJson(Map<String, dynamic> json){
        return CvJobs(
            agency: json["agency"] == null ? null : Agency.fromJson(json["agency"]),
            location: json["location"],
            hlTitle: json["hl_title"],
            logo: json["logo"],
            description: json["description"],
            url: json["url"],
            salary: json["salary"],
            applications: json["applications"],
            title: json["title"],
            id: json["id"],
            posted: DateTime.tryParse(json["posted"] ?? ""),
            type: json["type"] == null ? [] : List<String>.from(json["type"]!.map((x) => x)),
        );
    }

    Map<String, dynamic> toJson() => {
        "agency": agency?.toJson(),
        "location": location,
        "hl_title": hlTitle,
        "logo": logo,
        "description": description,
        "url": url,
        "salary": salary,
        "applications": applications,
        "title": title,
        "id": id,
        "posted": posted?.toIso8601String(),
        "type": type.map((x) => x).toList(),
    };

}

class Agency {
    Agency({
        required this.url,
        required this.type,
        required this.title,
    });

    final String? url;
    final String? type;
    final String? title;

    factory Agency.fromJson(Map<String, dynamic> json){ 
        return Agency(
            url: json["url"],
            type: json["type"],
            title: json["title"],
        );
    }

    Map<String, dynamic> toJson() => {
        "url": url,
        "type": type,
        "title": title,
    };

}