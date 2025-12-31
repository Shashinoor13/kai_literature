# Deploy Welcome Email - Quick Guide

## Prerequisites

- [ ] Firebase CLI installed (`firebase --version`)
- [ ] Firebase project on **Blaze (Pay-as-you-go)** plan
- [ ] Gmail account with App Password OR SendGrid account

## Step-by-Step Deployment

### 1. Install Function Dependencies

```bash
cd /Users/shashinoorghimire/Documents/v2/functions
npm install
```

Expected output: `added 326 packages`

### 2. Choose Email Service & Configure

#### Option A: Gmail (For Testing)

**Get Gmail App Password:**
1. Go to https://myaccount.google.com/security
2. Enable "2-Step Verification"
3. Go to "App passwords"
4. Generate password for "Mail"
5. Copy the 16-character password

**Set Firebase Config:**
```bash
cd /Users/shashinoorghimire/Documents/v2
firebase functions:config:set gmail.email="YOUR_EMAIL@gmail.com"
firebase functions:config:set gmail.password="xxxx-xxxx-xxxx-xxxx"
```

**Verify Config:**
```bash
firebase functions:config:get
```

#### Option B: SendGrid (For Production)

**Get SendGrid API Key:**
1. Sign up at https://sendgrid.com
2. Create API key with "Mail Send" permissions
3. Copy the API key

**Update Code:**
1. Open `functions/index.js`
2. Replace the nodemailer section with SendGrid code (see comments in file)
3. Install SendGrid: `npm install @sendgrid/mail`

**Set Firebase Config:**
```bash
firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"
```

### 3. Deploy the Function

```bash
cd /Users/shashinoorghimire/Documents/v2
firebase deploy --only functions:sendWelcomeEmail
```

Expected output:
```
✔  functions[sendWelcomeEmail(...)] Successful create operation.
Function URL: https://...
```

### 4. Test the Welcome Email

**Method 1: Sign up with new user**
1. Open your app
2. Sign up with a real email address
3. Check inbox (and spam folder)

**Method 2: Manually trigger (for testing)**
```bash
# In Firebase Console:
# Firestore → users → Add Document
# ID: test-user-123
# Fields:
#   - email: "your-test-email@gmail.com"
#   - username: "testuser"
```

### 5. Monitor Logs

```bash
# View logs
firebase functions:log --only sendWelcomeEmail

# Follow logs in real-time
firebase functions:log --only sendWelcomeEmail --follow
```

### 6. Deploy Story Cleanup Function (Optional)

```bash
firebase deploy --only functions:cleanupExpiredStories
```

## Verification Checklist

After deployment, verify:

- [ ] Function appears in Firebase Console → Functions
- [ ] Config is set: `firebase functions:config:get`
- [ ] Test user receives welcome email
- [ ] Email not in spam folder
- [ ] Email looks good on mobile and desktop
- [ ] Logs show successful email send

## Common Issues & Solutions

### Issue: "Firebase project must be on Blaze plan"

**Solution:**
1. Go to Firebase Console
2. Navigate to your project
3. Go to Settings → Usage and billing
4. Upgrade to Blaze (Pay-as-you-go) plan

### Issue: "UNAUTHENTICATED" error in logs

**Solution:**
```bash
# Check config
firebase functions:config:get

# Re-set credentials
firebase functions:config:set gmail.email="YOUR_EMAIL"
firebase functions:config:set gmail.password="YOUR_APP_PASSWORD"

# Redeploy
firebase deploy --only functions:sendWelcomeEmail
```

### Issue: Email not received

**Checklist:**
1. Check spam folder
2. View function logs: `firebase functions:log`
3. Verify email config is correct
4. Check Gmail app password is valid
5. Ensure user document has valid email field

### Issue: "Error: 7 PERMISSION_DENIED"

**Solution:**
Ensure Firebase project is on Blaze plan (external API calls require it)

## Email Deliverability (Production)

For best deliverability in production:

1. **Use SendGrid or similar service** (not Gmail)
2. **Verify your domain** with email provider
3. **Set up DNS records:**
   - SPF record
   - DKIM record
   - DMARC record
4. **Monitor bounce rates** and adjust
5. **Add unsubscribe link** (legal requirement in some regions)

## Cost Estimation

### Firebase Functions
- Free tier: 2M invocations/month
- After free tier: $0.40 per million invocations
- Expected cost for welcome emails: **~$0** (well within free tier)

### Email Service
- **Gmail**: Free (500 emails/day limit)
- **SendGrid Free**: 100 emails/day
- **SendGrid Essentials**: $19.95/month (50,000 emails/month)

## Next Steps After Deployment

1. Monitor email delivery rate for first week
2. Check email open rates (if using SendGrid)
3. Collect user feedback on welcome email
4. A/B test different email content
5. Add more automated emails (password reset, etc.)

## Rollback Instructions

If you need to remove the function:

```bash
firebase functions:delete sendWelcomeEmail
```

## Support

- Firebase Functions docs: https://firebase.google.com/docs/functions
- Nodemailer docs: https://nodemailer.com/
- SendGrid docs: https://docs.sendgrid.com/

---

**Quick Deploy Command:**
```bash
cd /Users/shashinoorghimire/Documents/v2 && \
firebase functions:config:set gmail.email="YOUR_EMAIL" gmail.password="YOUR_PASSWORD" && \
firebase deploy --only functions:sendWelcomeEmail
```

Replace `YOUR_EMAIL` and `YOUR_PASSWORD` with your actual credentials.
