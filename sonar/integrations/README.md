# SonarQube Webhook Integrations

This directory contains sample webhook handlers for integrating SonarQube with notification services like Telegram and Slack.

## Overview

SonarQube can send webhook notifications when analysis is complete. These scripts provide simple HTTP servers that receive those webhooks and forward formatted notifications to your preferred messaging platform.

## Available Integrations

### 1. Telegram (`telegram-webhook.sh`)

Sends SonarQube analysis results to a Telegram chat.

**Setup:**
1. Create a Telegram bot via [@BotFather](https://t.me/BotFather)
2. Get your chat ID by messaging your bot and visiting:
   ```
   https://api.telegram.org/bot<YourBOTToken>/getUpdates
   ```
3. Set environment variables:
   ```bash
   export TELEGRAM_BOT_TOKEN='your_bot_token'
   export TELEGRAM_CHAT_ID='your_chat_id'
   ```
4. Run the server:
   ```bash
   node /tmp/telegram-webhook-server.js
   ```

### 2. Slack (`slack-webhook.sh`)

Sends SonarQube analysis results to a Slack channel.

**Setup:**
1. Create an Incoming Webhook in your Slack workspace:
   - Go to Slack App Directory
   - Search for "Incoming Webhooks"
   - Add to your workspace
   - Copy the webhook URL
2. Set environment variable:
   ```bash
   export SLACK_WEBHOOK_URL='https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
   ```
3. Run the server:
   ```bash
   node /tmp/slack-webhook-server.js
   ```

## Configuring SonarQube Webhooks

1. Log in to SonarQube as an administrator
2. Go to **Administration** → **Configuration** → **Webhooks**
3. Click **Create**
4. Fill in the details:
   - **Name**: Telegram Notifications (or Slack Notifications)
   - **URL**: `http://your-server:3000/webhook` (or port 3001 for Slack)
   - **Secret**: (optional, for added security)
5. Click **Create**

## Production Deployment

These scripts are examples for development. For production:

### Option 1: Docker Container

Create a `Dockerfile`:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY telegram-webhook-server.js .
CMD ["node", "telegram-webhook-server.js"]
```

Build and run:
```bash
docker build -t sonarqube-telegram-webhook .
docker run -d -p 3000:3000 \
  -e TELEGRAM_BOT_TOKEN='your_token' \
  -e TELEGRAM_CHAT_ID='your_chat_id' \
  sonarqube-telegram-webhook
```

### Option 2: Serverless (AWS Lambda, Google Cloud Functions)

Convert the Node.js code to a serverless function handler:

```javascript
// AWS Lambda example
exports.handler = async (event) => {
    const payload = JSON.parse(event.body);
    const message = formatSonarQubeMessage(payload);
    await sendTelegramMessage(message);
    return { statusCode: 200, body: 'OK' };
};
```

### Option 3: Process Manager (PM2)

```bash
npm install -g pm2
pm2 start /tmp/telegram-webhook-server.js --name sonarqube-telegram
pm2 save
pm2 startup
```

## Security Considerations

- **Use HTTPS**: In production, always use HTTPS for webhook endpoints
- **Validate Webhooks**: Implement webhook signature validation using SonarQube's secret
- **Rate Limiting**: Add rate limiting to prevent abuse
- **Environment Variables**: Never hardcode tokens or secrets
- **Network Security**: Restrict access to webhook endpoints using firewalls

## Message Format

### Telegram
```
*SonarQube Analysis Complete* ✅

*Project:* My Project
*Branch:* main
*Quality Gate:* OK

*Conditions:*
• coverage: 85.5% (OK)
• bugs: 0 (OK)

[View Project](http://sonarqube/dashboard?id=my-project)
```

### Slack
Formatted as a rich attachment with:
- Color-coded based on quality gate status (green/red/yellow)
- Project details in fields
- Clickable "View Project" button

## Troubleshooting

### Webhook not received

1. Check that the webhook server is running:
   ```bash
   curl http://localhost:3000/webhook
   ```
2. Verify SonarQube can reach the webhook URL
3. Check SonarQube logs for webhook delivery errors

### Messages not sent

1. Verify environment variables are set correctly
2. Test the Telegram/Slack API directly:
   ```bash
   # Telegram
   curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
     -d "chat_id=${TELEGRAM_CHAT_ID}&text=Test"
   
   # Slack
   curl -X POST "${SLACK_WEBHOOK_URL}" \
     -H "Content-Type: application/json" \
     -d '{"text":"Test"}'
   ```

## Extending

You can extend these scripts to:
- Add more notification platforms (Discord, Microsoft Teams, etc.)
- Include more detailed metrics from the webhook payload
- Filter notifications based on project or quality gate status
- Store webhook history in a database
- Create custom dashboards

## Resources

- [SonarQube Webhooks Documentation](https://docs.sonarqube.org/latest/project-administration/webhooks/)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
