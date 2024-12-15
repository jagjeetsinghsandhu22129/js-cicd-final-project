provider "aws" {
  region = "us-east-1"  # Choose your desired region
}

# S3 Bucket for frontend hosting
resource "aws_s3_bucket" "frontend" {
  bucket = "python-web-app-frontend-bucket-unique-name-12345"  # Ensure a globally unique name
  acl    = "public-read"  # If you want public read access

  tags = {
    Name        = "Frontend Website"
    Environment = "Production"
  }
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.frontend.bucket
  key    = "index.html"
  source = "path/to/index.html"  # Path to your index.html file
  acl    = "public-read"  # Make the file publicly accessible
}

# Optionally, set up an error page
resource "aws_s3_bucket_object" "error_html" {
  bucket = aws_s3_bucket.frontend.bucket
  key    = "error.html"
  source = "path/to/error.html"  # Path to your error.html file
  acl    = "public-read"  # Make the file publicly accessible
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.bucket

  index_document = "index.html"
  error_document = "error.html"  # Optional for custom error pages
}



resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
 
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.frontend.id
 
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.block_public_access,
  ]
 
  bucket = aws_s3_bucket.frontend.id
  acl    = "public-read"
}


# Security Group for EC2 instance
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance for backend Flask app
resource "aws_instance" "flask_app" {
  ami             = "ami-0c55b159cbfafe1f0"  # Update this with a valid Ubuntu AMI ID for your region
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_sg.name]
  key_name        = "my-key-pair"  # Replace with your key pair name
  tags = {
    Name = "FlaskAppInstance"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y python3-pip python3-dev git
    sudo pip3 install flask
    git clone https://github.com/YOUR-REPOSITORY/python-web-app.git /home/ubuntu/python-web-app
    cd /home/ubuntu/python-web-app
    nohup python3 app.py &
  EOF
}

# IAM Role for EC2 instance to access S3
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "ec2_s3_policy"
  description = "Allow EC2 to access the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}
