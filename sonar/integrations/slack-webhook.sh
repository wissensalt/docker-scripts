#!/bin/bash

# Slack Webhook Handler for SonarQube
# This script receives SonarQube webhook payloads and sends notifications to Slack

# Configuration
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-https://hooks.slack.com/services/YOUR/WEBHOOK/URL}"
PORT="${PORT:-3001}"

# Function to send Slack message
send_slack_message() {
    local payload="$1"
    curl -s -X POST "${SLACK_WEBHOOK_URL}" \
        -H "Content-Type: application/json" \
        -d "${payload}"
}

# Function to format SonarQube webhook payload for Slack
format_slack_message() {
    local payload="$1"
    
    # Extract key information using jq
    local project_name=$(echo "$payload" | jq -r '.project.name // "Unknown"')
    local project_key=$(echo "$payload" | jq -r '.project.key // "Unknown"')
    local quality_gate=$(echo "$payload" | jq -r '.qualityGate.status // "Unknown"')
    local branch=$(echo "$payload" | jq -r '.branch.name // "main"')
    local server_url=$(echo "$payload" | jq -r '.serverUrl // ""')
    
    # Determine color based on quality gate status
    local color
    if [ "$quality_gate" = "OK" ]; then
        color="good"
    elif [ "$quality_gate" = "ERROR" ]; then
        color="danger"
    else
        color="warning"
    fi
    
    # Build Slack message with attachments
    local slack_payload=$(cat <<EOF
{
    "text": "SonarQube Analysis Complete",
    "attachments": [
        {
            "color": "${color}",
            "fields": [
                {
                    "title": "Project",
                    "value": "${project_name}",
                    "short": true
                },
                {
                    "title": "Branch",
                    "value": "${branch}",
                    "short": true
                },
                {
                    "title": "Quality Gate",
                    "value": "${quality_gate}",
                    "short": true
                }
            ],
            "actions": [
                {
                    "type": "button",
                    "text": "View Project",
                    "url": "${server_url}/dashboard?id=${project_key}"
                }
            ]
        }
    ]
}
EOF
)
    
    echo "$slack_payload"
}

# Example using Node.js (recommended for production)
cat > /tmp/slack-webhook-server.js << 'EOF'
const http = require('http');

const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;
const PORT = process.env.PORT || 3001;

async function sendSlackMessage(payload) {
    const response = await fetch(SLACK_WEBHOOK_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });
    return response.text();
}

function formatSlackMessage(payload) {
    const projectName = payload.project?.name || 'Unknown';
    const projectKey = payload.project?.key || 'Unknown';
    const qualityGate = payload.qualityGate?.status || 'Unknown';
    const branch = payload.branch?.name || 'main';
    const serverUrl = payload.serverUrl || '';
    
    // Determine color based on quality gate status
    let color = 'warning';
    if (qualityGate === 'OK') {
        color = 'good';
    } else if (qualityGate === 'ERROR') {
        color = 'danger';
    }
    
    // Build fields array
    const fields = [
        {
            title: 'Project',
            value: projectName,
            short: true
        },
        {
            title: 'Branch',
            value: branch,
            short: true
        },
        {
            title: 'Quality Gate',
            value: qualityGate,
            short: true
        }
    ];
    
    // Add conditions if they exist
    if (payload.qualityGate?.conditions) {
        const conditionsText = payload.qualityGate.conditions
            .map(c => `${c.metric}: ${c.value} (${c.status})`)
            .join('\n');
        
        fields.push({
            title: 'Conditions',
            value: conditionsText,
            short: false
        });
    }
    
    const slackPayload = {
        text: 'SonarQube Analysis Complete',
        attachments: [
            {
                color: color,
                fields: fields,
                actions: serverUrl ? [
                    {
                        type: 'button',
                        text: 'View Project',
                        url: `${serverUrl}/dashboard?id=${projectKey}`
                    }
                ] : []
            }
        ]
    };
    
    return slackPayload;
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
                const slackMessage = formatSlackMessage(payload);
                await sendSlackMessage(slackMessage);
                
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
    console.log(`Slack webhook handler listening on port ${PORT}`);
    console.log(`Webhook URL: http://localhost:${PORT}/webhook`);
});
EOF

echo "Starting Slack webhook handler on port ${PORT}..."
echo "Make sure SLACK_WEBHOOK_URL is set in your environment"
echo ""
echo "Node.js webhook server created at /tmp/slack-webhook-server.js"
echo ""
echo "To run the server:"
echo "  export SLACK_WEBHOOK_URL='https://hooks.slack.com/services/YOUR/WEBHOOK/URL'"
echo "  node /tmp/slack-webhook-server.js"
echo ""
echo "Then configure SonarQube webhook to point to: http://your-server:3001/webhook"
