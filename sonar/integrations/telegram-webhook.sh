#!/bin/bash

# Telegram Webhook Handler for SonarQube
# This script receives SonarQube webhook payloads and sends notifications to Telegram

# Configuration
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-your_bot_token_here}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-your_chat_id_here}"
PORT="${PORT:-3000}"

# Function to send Telegram message
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{\"chat_id\": \"${TELEGRAM_CHAT_ID}\", \"text\": \"${message}\", \"parse_mode\": \"Markdown\"}"
}

# Function to format SonarQube webhook payload
format_sonarqube_message() {
    local payload="$1"
    
    # Extract key information using jq
    local project_name=$(echo "$payload" | jq -r '.project.name // "Unknown"')
    local project_key=$(echo "$payload" | jq -r '.project.key // "Unknown"')
    local quality_gate=$(echo "$payload" | jq -r '.qualityGate.status // "Unknown"')
    local branch=$(echo "$payload" | jq -r '.branch.name // "main"')
    local server_url=$(echo "$payload" | jq -r '.serverUrl // ""')
    
    # Build message
    local status_emoji
    if [ "$quality_gate" = "OK" ]; then
        status_emoji="✅"
    elif [ "$quality_gate" = "ERROR" ]; then
        status_emoji="❌"
    else
        status_emoji="⚠️"
    fi
    
    local message="*SonarQube Analysis Complete* ${status_emoji}

*Project:* ${project_name}
*Branch:* ${branch}
*Quality Gate:* ${quality_gate}

"
    
    # Add conditions if they exist
    local conditions=$(echo "$payload" | jq -r '.qualityGate.conditions[]? | "• \(.metric): \(.value) (\(.status))"' 2>/dev/null)
    if [ -n "$conditions" ]; then
        message+="*Conditions:*
${conditions}

"
    fi
    
    # Add link to project
    if [ -n "$server_url" ]; then
        message+="[View Project](${server_url}/dashboard?id=${project_key})"
    fi
    
    echo "$message"
}

# Simple HTTP server using netcat (for demonstration)
# In production, use a proper web framework like Express.js, Flask, or FastAPI

echo "Starting Telegram webhook handler on port ${PORT}..."
echo "Make sure TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are set in your environment"

# Example using Node.js (recommended for production)
cat > /tmp/telegram-webhook-server.js << 'EOF'
const http = require('http');

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID;
const PORT = process.env.PORT || 3000;

async function sendTelegramMessage(message) {
    const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            chat_id: TELEGRAM_CHAT_ID,
            text: message,
            parse_mode: 'Markdown'
        })
    });
    return response.json();
}

function formatSonarQubeMessage(payload) {
    const projectName = payload.project?.name || 'Unknown';
    const projectKey = payload.project?.key || 'Unknown';
    const qualityGate = payload.qualityGate?.status || 'Unknown';
    const branch = payload.branch?.name || 'main';
    const serverUrl = payload.serverUrl || '';
    
    const statusEmoji = qualityGate === 'OK' ? '✅' : qualityGate === 'ERROR' ? '❌' : '⚠️';
    
    let message = `*SonarQube Analysis Complete* ${statusEmoji}\n\n`;
    message += `*Project:* ${projectName}\n`;
    message += `*Branch:* ${branch}\n`;
    message += `*Quality Gate:* ${qualityGate}\n\n`;
    
    if (payload.qualityGate?.conditions) {
        message += '*Conditions:*\n';
        payload.qualityGate.conditions.forEach(condition => {
            message += `• ${condition.metric}: ${condition.value} (${condition.status})\n`;
        });
        message += '\n';
    }
    
    if (serverUrl) {
        message += `[View Project](${serverUrl}/dashboard?id=${projectKey})`;
    }
    
    return message;
}

const server = http.createServer(async (req, res) => {
    if (req.method === 'POST' && req.url === '/webhook') {
        let body = '';
        
        req.on('data', chunk => {
            body += chunk.toString();
        });
        
        req.on('end', async () => {
            try {
                const payload = JSON.parse(body);
                const message = formatSonarQubeMessage(payload);
                await sendTelegramMessage(message);
                
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'ok' }));
            } catch (error) {
                console.error('Error processing webhook:', error);
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: error.message }));
            }
        });
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(PORT, () => {
    console.log(`Telegram webhook handler listening on port ${PORT}`);
    console.log(`Webhook URL: http://localhost:${PORT}/webhook`);
});
EOF

echo ""
echo "Node.js webhook server created at /tmp/telegram-webhook-server.js"
echo ""
echo "To run the server:"
echo "  export TELEGRAM_BOT_TOKEN='your_bot_token'"
echo "  export TELEGRAM_CHAT_ID='your_chat_id'"
echo "  node /tmp/telegram-webhook-server.js"
echo ""
echo "Then configure SonarQube webhook to point to: http://your-server:3000/webhook"
