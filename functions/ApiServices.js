import fetch from 'node-fetch';
import base64 from 'base-64';

export class ApiServices {
    constructor() {
        this.basicAuth = `Basic ${base64.encode('d9b1179f-f620-4742-a5cc-ece469c24d00:')}`;
    }

    async getFilesApi(title, town) {
        const url = `https://www.reed.co.uk/api/1.0/search?keywords=${encodeURIComponent(title)}&location=${encodeURIComponent(town)}`;
        try {
            const response = await fetch(url, {
                headers: {
                    'authorization': this.basicAuth,
                    'Content-Type': 'application/json',
                },
            });
            if (response.ok) {
                const data = await response.json();
                return data.results || [];
            } else {
                throw new Error('Failed to fetch from Reed API');
            }
        } catch (error) {
            console.error('Error in getFilesApi:', error);
            return [];
        }
    }

    async getCvLibraryJob(cvtitle, cvlocation) {
        const url = `https://www.cv-library.co.uk/search-jobs-json?key=zkM61g6mb,9z-byL&q=${encodeURIComponent(cvtitle)}&perpage=25&offset=0&location=${encodeURIComponent(cvlocation)}&description_limit=400`;
        try {
            const response = await fetch(url);
            if (response.ok) {
                const data = await response.json();
                // Transform the jobs data to ensure consistent property names
                return (data.jobs || []).map(job => ({
                    jobTitle: job.title,
                    location: job.location,
                    salary: job.salary || 'Competitive salary',
                    url: job.url || job.applyurl || `https://www.cv-library.co.uk${job.jobUrl}`,
                    // Add any other necessary fields
                }));
            } else {
                throw new Error('Failed to fetch from CV Library API');
            }
        } catch (error) {
            console.error('Error in getCvLibraryJob:', error);
            return [];
        }
    }
}