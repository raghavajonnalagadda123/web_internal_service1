This project demonstrates automated infrastructure and application deployment using **GitHub Actions**, **Bedrock**, **Sage**, **Terraform**, and **Prometheus + Grafana** for observability.

---

## 1️⃣ Project Objective

This project showcases the ability to:

- 🤖 **Automate deployment** using GitHub Actions (parallel & cache-efficient)
- ☁️ **Deploy infrastructure and applications** to GCP or any Linux server
- 📊 **Integrate observability** using Prometheus and Grafana

---

## 2️⃣ Project Base Setup

### 2.1 Fork & Clone Bedrock
```bash
git clone https://github.com/roots/bedrock web_internal_service
cd web_internal_service
```
2.2 Install Sage Theme

Clone the Sage theme under web/app/themes/:
```bash
cd web/app/themes
git clone https://github.com/roots/sage.git sage
cd sage
npm install
npm run build
```

✅ Output: web/app/themes/sage/public/build/assets/

2.3 Install WordPress Plugins via Composer

Add plugins to composer.json in the Bedrock root:
```bash
"require": {
  "wpackagist-plugin/woocommerce": "^8.0",
  "wpackagist-plugin/wordpress-seo": "^20.0"
}
```
Then run:

composer update


✅ Ensures plugins are installed and managed via Composer.

3️⃣ Server Setup
3.1 Server Requirements

Ubuntu 22.04 LTS

Nginx

PHP 8.1 with PHP-FPM

MySQL 8.0

Node.js v20+

Composer & Git

3.2 Installation Commands
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nginx mysql-server php8.1-fpm php8.1-mysql php8.1-cli php8.1-curl php8.1-xml php8.1-mbstring unzip git composer -y
```

# Install Node.js v20
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

3.3 Database Setup
```bash
sudo mysql
CREATE DATABASE bedrock_db;
CREATE USER 'bedrock_user'@'localhost' IDENTIFIED BY 'StrongPassword';
GRANT ALL PRIVILEGES ON bedrock_db.* TO 'bedrock_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

3.4 Configure .env
```bash
DB_NAME=bedrock_db
DB_USER=bedrock_user
DB_PASSWORD=StrongPassword
DB_HOST=localhost
```

4️⃣ Bedrock & Sage Theme Setup
```bash
cd /home/deploy/web_internal_service/bedrock
composer install
```

# Sage theme setup
```bash
cd web/app/themes
git clone https://github.com/roots/sage.git sage
cd sage
npm install
npm run build
```


✅ Output: web/app/themes/sage/public/build/assets/

5️⃣ Nginx Configuration
5.1 Create Config File


/etc/nginx/sites-available/bedrock
```bash
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /home/deploy/web_internal_service/bedrock/web;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

5.2 Enable & Reload Nginx
```bash
sudo ln -s /etc/nginx/sites-available/bedrock /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

5.3 Fix Permissions
```bash
sudo chown -R www-data:www-data /home/deploy/web_internal_service/bedrock/web
sudo find /home/deploy/web_internal_service/bedrock/web -type d -exec chmod 755 {} \;
sudo find /home/deploy/web_internal_service/bedrock/web -type f -exec chmod 644 {} \;
```

6️⃣ Test PHP-FPM
```bash
echo "<?php phpinfo(); ?>" | sudo tee /home/deploy/web_internal_service/bedrock/web/test.php
```


Visit:
👉 http://YOUR_SERVER_IP/test.php
✅ Should display PHP info page.

7️⃣ GitHub Actions CI/CD Setup

File: .github/workflows/deploy.yml

7.1 Triggers

On push to main

Manual trigger (workflow_dispatch)

7.2 Build Stage

Install dependencies via composer install (Bedrock)

Parallel tasks:

npm install + npm run build for Sage theme

Plugin installation

Efficient caching (Composer + npm)

Create release with built resources

7.3 Deployment Stage

Deployment targets:

✅ GCP Compute Engine VM

✅ Cloud Run / GKE (optional)

✅ Linux VM (fallback)

Includes:

Credentials via GitHub Secrets

Health check via curl

Optional rollback logic

8️⃣ Observability: Prometheus + Grafana

File: monitoring/docker-compose.yml

Services

Prometheus

Node Exporter (server metrics)

Grafana

Dashboards

CPU & RAM usage (Node Exporter)

HTTP availability of deployed Bedrock site

Optional Enhancements

Secure Grafana via basic auth/OAuth

Alerts to Slack/webhook

Provision Prometheus/Grafana via Terraform/Ansible

9️⃣ Terraform Setup

Example: main.tf
```bash
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "monitoring_vm" {
  ami           = "ami-0c2b8ca1dad447f8a"
  instance_type = "t2.medium"
  key_name      = "your-ssh-key"
  subnet_id     = "subnet-xxxxxxxx"
  vpc_security_group_ids = ["sg-xxxxxxxx"]

  user_data = <<-EOT
    #!/bin/bash
    apt update && apt upgrade -y
    apt install -y nginx mysql-server php8.1-fpm php8.1-mysql php8.1-cli php8.1-curl php8.1-xml php8.1-mbstring unzip git composer
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    mysql -e "CREATE DATABASE IF NOT EXISTS bedrock_db;"
    mysql -e "CREATE USER IF NOT EXISTS 'bedrock_user'@'localhost' IDENTIFIED BY 'StrongPassword';"
    mysql -e "GRANT ALL PRIVILEGES ON bedrock_db.* TO 'bedrock_user'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    apt install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
    git clone https://github.com/raghavajonnalagadda123/web_internal_service1 /home/deploy/monitoring
    cd /home/deploy/monitoring
    docker-compose up -d
  EOT

  tags = {
    Name = "Monitoring-VM"
  }
}
```

🔟 Testing & Access

Frontend: http://YOUR_SERVER_IP/

Admin: http://YOUR_SERVER_IP/wp/wp-admin

1️⃣1️⃣ Notes / Best Practices

🔐 Store all credentials in GitHub Secrets

⚡ Use Composer & npm caches to speed up CI/CD

💚 Health checks ensure deployment reliability

📈 Observability enables proactive monitoring

🧱 Terraform automates VM creation & setup


