provider "aws" {
  region = "us-east-1"  # change as needed
}

resource "aws_instance" "monitoring_vm" {
  ami           = "ami-0c2b8ca1dad447f8a"  # Ubuntu 22.04 AMI for your region
  instance_type = "t2.medium"
  key_name      = "your-ssh-key"          # ensure this key exists in AWS
  subnet_id     = "subnet-xxxxxxxx"       # optional, default VPC if blank
  vpc_security_group_ids = ["sg-xxxxxxxx"] # allow SSH, HTTP, 3000, 9090, 9093

  user_data = <<-EOT
    #!/bin/bash
    set -e

    # Update and upgrade
    apt update && apt upgrade -y

    # Install Nginx, MySQL, PHP, Git, Composer
    apt install -y nginx mysql-server php8.1-fpm php8.1-mysql php8.1-cli php8.1-curl php8.1-xml php8.1-mbstring unzip git composer

    # Install Node.js v20
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs

    # Setup MySQL Database
    mysql -e "CREATE DATABASE IF NOT EXISTS bedrock_db;"
    mysql -e "CREATE USER IF NOT EXISTS 'bedrock_user'@'localhost' IDENTIFIED BY 'StrongPassword';"
    mysql -e "GRANT ALL PRIVILEGES ON bedrock_db.* TO 'bedrock_user'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

    # Enable & start services
    systemctl enable nginx
    systemctl start nginx
    systemctl enable mysql
    systemctl start mysql

    # Install Docker & Docker Compose
    apt install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker

    # Clone your monitoring repo and start Docker Compose
    git clone https://github.com/kushwahvishal939/web_internal_service.git /home/deploy/monitoring
    cd /home/deploy/monitoring
    docker-compose up -d

  EOT

  tags = {
    Name = "Monitoring-VM"
  }
}

