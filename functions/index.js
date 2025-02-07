import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { onRequest } from 'firebase-functions/v2/https';
import nodemailer from 'nodemailer';
import cors from 'cors';
import { ApiServices } from './ApiServices.js';

initializeApp();
const db = getFirestore();
const corsMiddleware = cors({ origin: true });

// Configure Nodemailer using environment variables
const emailUser = process.env.EMAIL_USER || 'olayemi.abdullahi9585@gmail.com';
const emailPass = process.env.EMAIL_PASS || 'ktrrffyquubmrvim';

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: emailUser, pass: emailPass },
});

function generateEmailTemplate(matchingJobs, unsubscribeUrl) {
    return `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                .container { max-width: 600px; margin: auto; font-family: Arial, sans-serif; }
                .header { background: linear-gradient(to right, #FFE0C2, #7FFFD4); padding: 20px; text-align: center; }
                .job-card { border: 1px solid #eee; padding: 15px; margin: 10px 0; border-radius: 5px; }
                .job-source { color: #666; font-size: 12px; margin-bottom: 5px; }
                .apply-button { background: #4CAF50; color: white; padding: 8px 15px; text-decoration: none; border-radius: 3px; display: inline-block; margin-top: 10px; }
                .footer { background: #f5f5f5; padding: 15px; text-align: center; font-size: 12px; }
                .unsubscribe { color: #666; text-decoration: underline; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Your Job Matches</h1>
                </div>
                ${matchingJobs.map(job => `
                    <div class="job-card">
                        <div class="job-source">Source: ${job.source || 'Reed'}</div>
                        <h3>${job.jobTitle || job.hlTitle}</h3>
                        <p>${job.locationName || job.location}</p>
                        <p>${job.salary ?? 'Competitive salary'}</p>
                        <a href="${job.url || job.jobUrl}" class="apply-button">Apply Now</a>
                    </div>
                `).join('')}
                <div class="footer">
                    <p>You received this email because you're subscribed to job alerts on Tuned Jobs.</p>
                    <p><a href="${unsubscribeUrl}" class="unsubscribe">Unsubscribe</a> from these alerts</p>
                </div>
            </div>
        </body>
        </html>
    `;
}

export const sendJobAlerts = onRequest({
    memory: '256MiB',
    region: 'us-central1',
}, (req, res) => {
    corsMiddleware(req, res, async () => {
        try {
            console.log('Starting job alerts processing');
            const apiServices = new ApiServices();

            // Fetch all alerts
            const alertsSnapshot = await db.collection('jobAlerts').get();
            const alerts = alertsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            console.log(`Found ${alerts.length} total alerts`);

            const processedAlerts = await Promise.all(alerts.map(async (alert) => {
                if (!alert.emailNotification) {
                    console.log(`Skipping alert ${alert.id} - email notifications disabled`);
                    return null;
                }

                try {
                    console.log(`Processing alert ${alert.id} for ${alert.jobTitle} in ${alert.location}`);

                    // Fetch jobs from both APIs
                    const [cvJobs, reedJobs] = await Promise.all([
                        apiServices.getCvLibraryJob(alert.jobTitle, alert.location),
                        apiServices.getFilesApi(alert.jobTitle, alert.location)
                    ]);

                    console.log(`Jobs found for alert ${alert.id}:`, {
                        cvLibraryCount: cvJobs.length,
                        reedCount: reedJobs.length
                    });

                    // Combine and limit the number of jobs
                    const matchingJobs = [...cvJobs.slice(0, 2), ...reedJobs.slice(0, 1)];

                    if (matchingJobs.length === 0) {
                        console.log(`No matching jobs found for alert ${alert.id}`);
                        return {
                            success: false,
                            email: alert.userEmail,
                            error: 'No matching jobs found'
                        };
                    }

                    // Generate unsubscribe URL
                    const unsubscribeUrl = `https://your-app-url.com/unsubscribe?alertId=${alert.id}&email=${encodeURIComponent(alert.userEmail)}`;

                    // Prepare email
                    const mailOptions = {
                        from: `Tuned Jobs <${emailUser}>`,
                        to: alert.userEmail,
                        subject: `Latest ${alert.jobTitle} Jobs in ${alert.location}`,
                        html: generateEmailTemplate(matchingJobs, unsubscribeUrl),
                    };

                    // Send email
                    await transporter.sendMail(mailOptions);
                    console.log(`Alert email sent successfully to ${alert.userEmail}`);

                    return {
                        success: true,
                        email: alert.userEmail,
                        jobsCounts: {
                            cv: cvJobs.length,
                            reed: reedJobs.length,
                            total: matchingJobs.length
                        }
                    };
                } catch (error) {
                    console.error(`Error processing alert ${alert.id} for ${alert.userEmail}:`, error);
                    return {
                        success: false,
                        email: alert.userEmail,
                        error: error.message
                    };
                }
            }));

            // Filter out null results and prepare response
            const results = processedAlerts.filter(result => result !== null);
            const successful = results.filter(r => r.success);
            const failed = results.filter(r => !r.success);

            console.log('Job alerts processing completed', {
                total: results.length,
                successful: successful.length,
                failed: failed.length
            });

            res.status(200).json({
                message: 'Job alerts processed',
                successful: successful.length,
                failed: failed.length,
                details: results
            });

        } catch (error) {
            console.error('Error processing job alerts:', error);
            res.status(500).json({
                error: 'Failed to process job alerts',
                details: error.message
            });
        }
    });
});

export const handleUnsubscribe = onRequest({
    memory: '256MiB',
    region: 'us-central1',
}, (req, res) => {
    corsMiddleware(req, res, async () => {
        try {
            const { alertId, email } = req.query;

            if (!alertId) {
                throw new Error('Alert ID is required');
            }

            console.log(`Processing unsubscribe request for alert ${alertId}`);

            const alertRef = db.collection('jobAlerts').doc(alertId);
            const alertDoc = await alertRef.get();

            if (!alertDoc.exists) {
                throw new Error('Alert not found');
            }

            // Verify the email matches if provided
            if (email && alertDoc.data().userEmail !== email) {
                throw new Error('Invalid unsubscribe request');
            }

            await alertRef.update({
                emailNotification: false,
                updatedAt: new Date().toISOString()
            });

            console.log(`Successfully unsubscribed alert ${alertId}`);

            res.send(`
                <!DOCTYPE html>
                <html>
                <head>
                    <style>
                        body {
                            font-family: Arial, sans-serif;
                            text-align: center;
                            padding: 40px;
                            background: #f5f5f5;
                        }
                        .container {
                            background: white;
                            padding: 20px;
                            border-radius: 8px;
                            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                            max-width: 500px;
                            margin: 0 auto;
                        }
                        h2 { color: #4CAF50; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h2>Successfully Unsubscribed</h2>
                        <p>You will no longer receive job alerts for this search.</p>
                        <p>You can always reactivate alerts from your account settings.</p>
                    </div>
                </body>
                </html>
            `);
        } catch (error) {
            console.error('Unsubscribe error:', error);
            res.status(500).json({
                error: 'Failed to unsubscribe',
                details: error.message
            });
        }
    });
});