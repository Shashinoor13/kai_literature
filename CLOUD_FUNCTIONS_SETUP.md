# Cloud Functions Setup Guide

## Quick Start

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Email (Choose One Option)

#### Option A: Gmail (Easiest - Good for Testing)

**Step 1:** Create a Gmail App Password
1. Go to your Google Account: https://myaccount.google.com/
2. Navigate to Security → 2-Step Verification (enable if not already)
3. Go to Security → App passwords
4. Generate a new app password for "Mail"
5. Copy the 16-character password

**Step 2:** Set Firebase configuration
```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="xxxx-xxxx-xxxx-xxxx"
```

**Note:** Gmail has sending limits (500 emails/day). Use SendGrid for production.

#### Option B: SendGrid (Recommended for Production)

**Step 1:** Create SendGrid account
1. Sign up at https://sendgrid.com (free tier: 100 emails/day)
2. Create an API key with "Mail Send" permissions
3. Copy the API key

**Step 2:** Update `functions/index.js`
```javascript
// Replace the nodemailer transporter with SendGrid
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(functions.config().sendgrid.key);

const mailOptions = {
  from: "noreply@literature.app",
  to: email,
  subject: "Welcome to Literature! 🎉",
  html: getWelcomeEmailHTML(username),
  text: getWelcomeEmailText(username),
};

await sgMail.send(mailOptions);
```

**Step 3:** Install SendGrid package
```bash
cd functions
npm install @sendgrid/mail
```

**Step 4:** Set configuration
```bash
firebase functions:config:set sendgrid.key="your-api-key"
```

### 3. Deploy Functions

```bash
# Make sure you're in the project root directory
cd /path/to/your/project

# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendWelcomeEmail
```

### 4. Test the Welcome Email

**Method 1: Create a test user in your app**
1. Sign up with a new email address
2. Check your inbox for the welcome email
3. Check spam folder if not received

**Method 2: Use Firebase Emulator (Local Testing)**
```bash
# Start emulators
cd functions
npm run serve

# In another terminal, create a test user document
# The function will trigger locally
```

### 5. Monitor Logs

```bash
# View all function logs
firebase functions:log

# View specific function logs
firebase functions:log --only sendWelcomeEmail

# Follow logs in real-time
firebase functions:log --only sendWelcomeEmail --follow
```

## Email Customization

### Change Email Content

Edit `functions/index.js`:

```javascript
function getWelcomeEmailHTML(username) {
  return `
    <!DOCTYPE html>
    <html>
      <head>...</head>
      <body>
        <!-- Your custom HTML here -->
        <h1>Welcome ${username}!</h1>
      </body>
    </html>
  `;
}
```

### Change Sender Name/Email

In `functions/index.js`:
```javascript
from: `"Your App Name" <noreply@yourdomain.com>`
```

### Change Subject Line

In `functions/index.js`:
```javascript
subject: "Your Custom Subject Line"
```

## Important Notes

### Firebase Pricing
- Welcome emails require Firebase **Blaze (Pay-as-you-go)** plan
- Cloud Functions have a free tier (2M invocations/month)
- External API calls (like email sending) require Blaze plan
- SendGrid free tier: 100 emails/day
- Gmail: 500 emails/day (not recommended for production)

### Production Checklist
- [ ] Switch from Gmail to SendGrid or similar service
- [ ] Verify sender domain with email provider
- [ ] Set up SPF, DKIM, DMARC records for deliverability
- [ ] Test email in spam checkers
- [ ] Monitor Cloud Functions quotas and costs
- [ ] Set up error alerting
- [ ] Add unsubscribe link (if required by law)

### Troubleshooting

**"UNAUTHENTICATED" error**
- Check email configuration: `firebase functions:config:get`
- Verify Gmail app password is correct
- Ensure 2-step verification is enabled for Gmail

**Emails not sending**
- Check function logs: `firebase functions:log`
- Verify Firebase project is on Blaze plan
- Check spam folder
- Verify email service credentials

**Function not triggering**
- Ensure function is deployed: `firebase deploy --only functions`
- Check Firestore trigger path matches: `users/{userId}`
- View logs for errors

**Deployment fails**
- Run `npm install` in functions directory
- Check Node.js version (requires Node 18)
- Verify `firebase.json` is configured correctly

## Next Steps

1. **Deploy the function**: `firebase deploy --only functions:sendWelcomeEmail`
2. **Configure email service**: Follow Option A or B above
3. **Test with a new user signup**
4. **Monitor logs**: `firebase functions:log`
5. **Customize email template** to match your brand

## Additional Functions Included

### cleanupExpiredStories
- Runs every hour automatically
- Deletes stories older than 24 hours
- Updates user's `hasActiveStory` field
- No configuration needed

Deploy with:
```bash
firebase deploy --only functions:cleanupExpiredStories
```

## Support

For issues:
1. Check Firebase Console → Functions → Logs
2. Review `functions/README.md`
3. See Firebase Functions documentation: https://firebase.google.com/docs/functions
