# Production Deployment Guide

This document describes the step-by-step procedure to deploy the FastAPI backend, MongoDB database, and Nginx reverse proxy to a production Linux server environment (e.g. Ubuntu 22.04 LTS).

---

## 🏗 System Topology

```
                       [ HTTPS Port 443 ]
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Nginx Reverse Proxy │ (TLS / SSL Termination, Body Limit 10M)
                    └──────────┬──────────┘
                               │ HTTP Port 8000 (Internal Loopback)
                               ▼
                    ┌─────────────────────┐
                    │ Gunicorn / Uvicorn  │ (4 Async Worker Processes)
                    │  FastAPI Backend    │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  MongoDB Instance   │ (Auth Enabled, Production Indexes)
                    └─────────────────────┘
```

---

## 1. 🖥 Server Provisioning & Dependencies

### Update Server Packages
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip python3-venv nginx certbot python3-certbot-nginx git mongodb-org
```

---

## 2. 🐍 Backend Setup & Virtual Environment

```bash
# Create application deployment directory
sudo mkdir -p /var/www/mentor_app
sudo chown -R $USER:$USER /var/www/mentor_app

# Clone repository / upload production build
cd /var/www/mentor_app
git clone https://github.com/your-org/mentor_student_app.git .

# Create virtualenv & install backend requirements
cd backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Configure Production `.env`
```bash
cp .env.example .env
nano .env
```
Ensure `JWT_SECRET_KEY`, `MONGODB_URL`, and `GEMINI_API_KEY` are populated with production secrets.

---

## 3. ⚙️ Systemd Service Configuration

Create a Systemd service to manage the FastAPI service process automatically.

Create file `/etc/systemd/system/mentor_backend.service`:

```ini
[Unit]
Description=College Mentor Student System FastAPI Backend
After=network.target mongodb.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/mentor_app/backend
EnvironmentFile=/var/www/mentor_app/backend/.env
ExecStart=/var/www/mentor_app/backend/venv/bin/gunicorn \
          -w 4 \
          -k uvicorn.workers.UvicornWorker \
          --bind 127.0.0.1:8000 \
          --access-logfile /var/log/mentor_app/access.log \
          --error-logfile /var/log/mentor_app/error.log \
          app.main:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Enable & Start Service
```bash
sudo mkdir -p /var/log/mentor_app
sudo chown -R www-data:www-data /var/log/mentor_app /var/www/mentor_app

sudo systemctl daemon-reload
sudo systemctl enable mentor_backend
sudo systemctl start mentor_backend
sudo systemctl status mentor_backend
```

---

## 4. 🌐 Nginx Reverse Proxy Configuration

Create file `/etc/nginx/sites-available/mentor_app`:

```nginx
server {
    listen 80;
    server_name api.mentorapp.college.edu;

    # Enforce maximum upload size for student document submissions (10 MB)
    client_max_body_size 10M;

    # Serve static uploaded files safely
    location /uploads/ {
        alias /var/www/mentor_app/backend/uploads/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # Reverse proxy to FastAPI Gunicorn server
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;
    }
}
```

### Enable Site & Test Nginx Config
```bash
sudo ln -s /etc/nginx/sites-available/mentor_app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 5. 🔒 SSL / TLS Certificate (Let's Encrypt)

Obtain free SSL certificate via Certbot:

```bash
sudo certbot --nginx -d api.mentorapp.college.edu
```
Certbot will automatically update Nginx to redirect HTTP (port 80) to HTTPS (port 443).

---

## 6. 🗄 MongoDB Production Hardening & Backups

### Execute Database Indexing
```bash
cd /var/www/mentor_app/backend
source venv/bin/activate
python3 app/database/create_indexes.py
```

### Daily Automated Backup Cron Job
Create `/etc/cron.daily/mentor_db_backup`:

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/mentor_db"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "$BACKUP_DIR"
mongodump --db=mentor_student_db --out="$BACKUP_DIR/$TIMESTAMP"
find "$BACKUP_DIR" -type d -mtime +14 -exec rm -rf {} +
```

Make executable:
```bash
sudo chmod +x /etc/cron.daily/mentor_db_backup
```

---

## 7. 📊 Verification & Health Monitoring

Verify the production deployment by pinging the health endpoint:

```bash
curl -i https://api.mentorapp.college.edu/api/v1/health
```

Expected HTTP Status: `200 OK`
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "version": "1.0.0",
    "database": "connected"
  },
  "message": "Service is operating normally"
}
```
