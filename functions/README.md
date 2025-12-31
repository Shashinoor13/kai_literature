# Literature Cloud Functions

Cloud Functions for the Literature app, including welcome emails and automated tasks.

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Email Service

You have several options for sending emails:

#### Option A: Gmail (Easiest for testing)

1. Create a Gmail App Password:
   - Go to your Google Account settings
   - Enable 2-Step Verification
   - Generate an App Password for "Mail"

2. Set Firebase config:
```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-app-password"
```

#### Option B: SendGrid (Recommended for production)

1. Sign up at https://sendgrid.com
2. Create an API key
3. Update `functions/index.js` to use SendGrid:

```javascript
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(functions.config().sendgrid.key);
```

4. Set config:
```bash
firebase functions:config:set sendgrid.key="your-sendgrid-api-key"
```

#### Option C: Custom SMTP Server

Update the `nodemailer.createTransport()` configuration in `functions/index.js`:

```javascript
const transporter = nodemailer.createTransport({
  host: "your-smtp-server.com",
  port: 587,
  secure: false,
  auth: {
    user: functions.config().smtp.user,
    pass: functions.config().smtp.password,
  },
});
```

### 3. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendWelcomeEmail
```

### 4. Test Locally (Optional)

```bash
# Start emulators
npm run serve

# Or use Firebase CLI
firebase emulators:start --only functions,firestore
```

## Available Functions

### sendWelcomeEmail
- **Trigger**: Firestore onCreate - `users/{userId}`
- **Purpose**: Sends a welcome email when a new user signs up
- **Email**: Beautiful HTML welcome email with app information

### cleanupExpiredStories
- **Trigger**: Scheduled (every 1 hour)
- **Purpose**: Deletes stories older than 24 hours and updates user's `hasActiveStory` field

## Environment Variables

View current config:
```bash
firebase functions:config:get
```

Set a config value:
```bash
firebase functions:config:set key.subkey="value"
```

Unset a config value:
```bash
firebase functions:config:unset key.subkey
```

## Monitoring

View function logs:
```bash
# All logs
firebase functions:log

# Specific function
firebase functions:log --only sendWelcomeEmail

# Real-time logs
firebase functions:log --only sendWelcomeEmail --follow
```

## Development

Lint your code:
```bash
npm run lint
```

## Important Notes

- Welcome emails are sent automatically when a user document is created in Firestore
- Make sure to configure email credentials before deploying
- Gmail has sending limits - use SendGrid or similar for production
- The welcome email includes the username from the user document
- Email failures are logged but don't block user registration

## Customization

### Customize Welcome Email

Edit the `getWelcomeEmailHTML()` and `getWelcomeEmailText()` functions in `functions/index.js`.

### Add More Functions

Follow the pattern in `index.js`:

```javascript
exports.yourFunctionName = functions.firestore
  .document('collection/{docId}')
  .onCreate(async (snap, context) => {
    // Your logic here
  });
```

## Troubleshooting

**Email not sending?**
- Check Firebase Functions logs: `firebase functions:log`
- Verify email configuration: `firebase functions:config:get`
- Test with Firebase emulator first
- Check spam folder for test emails

**Permission errors?**
- Ensure Firebase project has Blaze (pay-as-you-go) plan for external API calls
- Check IAM permissions in Firebase Console

**Function not triggering?**
- Verify the function is deployed: `firebase functions:list`
- Check Firestore collection path matches the trigger
- View logs for errors: `firebase functions:log`
