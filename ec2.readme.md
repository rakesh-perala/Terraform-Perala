# Terraform AWS EC2 – Enterprise-Level Infrastructure

## 📌 Project Overview

This project demonstrates how to provision an AWS EC2 server using **Terraform** with an enterprise-style Terraform structure.

The infrastructure includes:

* AWS Default VPC
* Security Group
* SSH access
* HTTP access
* AWS Key Pair
* Latest Ubuntu 24.04 AMI lookup
* EC2 instance
* Root EBS volume
* Terraform Variables
* Terraform tfvars
* Terraform Outputs
* Resource dependency management
* Infrastructure validation
* Enterprise security and operational practices

The objective is not only to create an EC2 instance, but also to understand **how Terraform code is structured and managed in real DevOps environments**.

---

# 1. Business Requirement

Imagine an organization needs a Linux server for hosting an application.

The DevOps team receives the following requirement:

> "Create an Ubuntu server in AWS with SSH access for administration, HTTP access for the application, a 15 GB GP3 root volume, and a unique server name."

Instead of manually creating the server from the AWS Console, the DevOps team uses Terraform.

### Traditional approach

```text
DevOps Engineer
      |
      v
AWS Console
      |
      +---- Create VPC
      |
      +---- Create Security Group
      |
      +---- Create Key Pair
      |
      +---- Create EC2
      |
      +---- Configure Storage
      |
      v
EC2 Server
```

Problems:

* Manual work
* Configuration mistakes
* Difficult to reproduce
* Difficult to audit
* Difficult to maintain multiple environments

---

# 2. Terraform Approach

With Terraform:

```text
Git Repository
      |
      v
Terraform Code
      |
      +---- main.tf
      |
      +---- variables.tf
      |
      +---- terraform.tfvars
      |
      +---- outputs.tf
      |
      v
terraform plan
      |
      v
terraform apply
      |
      v
AWS
      |
      +---- VPC
      +---- Security Group
      +---- Key Pair
      +---- EC2
      +---- EBS
```

Terraform becomes the **Infrastructure as Code (IaC)** tool.

---

# 3. Enterprise Architecture

```text
                         Developer / DevOps Engineer
                                  |
                                  |
                                  v
                         Git Repository
                                  |
                                  v
                       Terraform Configuration
                                  |
             +--------------------+--------------------+
             |                    |                    |
             v                    v                    v
          main.tf           variables.tf       terraform.tfvars
             |                    |                    |
             +--------------------+--------------------+
                                  |
                                  v
                             outputs.tf
                                  |
                                  v
                         terraform init
                                  |
                                  v
                         terraform validate
                                  |
                                  v
                           terraform plan
                                  |
                                  v
                           terraform apply
                                  |
                                  v
                         AWS Infrastructure
                                  |
             +--------------------+--------------------+
             |                    |                    |
             v                    v                    v
         Default VPC        Security Group         Key Pair
                                  |
                                  v
                              EC2 Instance
                                  |
                                  v
                              EBS Volume
                                  |
                                  v
                           Ubuntu Application
```

---

# 4. Real-Time Enterprise Scenario

Consider a company called:

**ABC Technologies**

They need an application build server.

The DevOps engineer creates:

```text
Server Name     : buildserver
Operating System: Ubuntu 24.04
Instance Type   : t2.micro
Root Disk       : 15 GB GP3
SSH             : Port 22
HTTP            : Port 80
```

Terraform provisions everything consistently.

Later the organization needs:

```text
Development
QA
Production
```

Instead of rewriting Terraform resources, variables can be changed for each environment.

For example:

```text
Development
t2.micro

QA
t3.micro

Production
t3.large
```

The infrastructure code remains reusable.

---

# 5. Project Structure

Recommended structure:

```text
terraform-ec2/
│
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── provider.tf
├── .gitignore
│
├── rakesh-key-ec2
└── rakesh-key-ec2.pub
```

### File responsibilities

| File               | Purpose                                |
| ------------------ | -------------------------------------- |
| `main.tf`          | AWS resources                          |
| `variables.tf`     | Variable declarations                  |
| `terraform.tfvars` | Actual variable values                 |
| `outputs.tf`       | Values displayed after deployment      |
| `provider.tf`      | AWS provider configuration             |
| `.gitignore`       | Prevent sensitive/local files from Git |

---

# 6. provider.tf

Create:

```hcl
provider "aws" {
  region = "us-east-1"
}
```

Change the region if required.

For Mumbai:

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

### Why provider.tf?

The provider tells Terraform:

> "Which cloud platform and region should Terraform communicate with?"

---

# 7. main.tf

The `main.tf` file contains the actual AWS infrastructure.

```hcl
# ============================================================
# Ubuntu AMI
# ============================================================

data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


# ============================================================
# Key Pair
# ============================================================

resource "aws_key_pair" "my_key" {

  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


# ============================================================
# Default VPC
# ============================================================

resource "aws_default_vpc" "default" {
}


# ============================================================
# Security Group
# ============================================================

resource "aws_security_group" "my_security_group" {

  name        = var.security_group_name
  description = "Terraform generated security group"

  vpc_id = aws_default_vpc.default.id

  # SSH
  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

    description = "HTTP access"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]

    description = "Allow outbound traffic"
  }

  tags = {
    Name = var.security_group_tag
  }
}


# ============================================================
# EC2 Instance
# ============================================================

resource "aws_instance" "my_instance" {

  ami = data.aws_ami.ubuntu.id

  instance_type = var.instance_type

  key_name = aws_key_pair.my_key.key_name

  vpc_security_group_ids = [
    aws_security_group.my_security_group.id
  ]

  root_block_device {

    volume_size = var.root_volume_size

    volume_type = var.root_volume_type
  }

  tags = {
    Name = var.instance_name
  }
}
```

---

# 8. Understanding the AMI Data Source

This section:

```hcl
data "aws_ami" "ubuntu" {
```

is a Terraform **data source**.

A data source reads information that already exists or is published externally.

Here Terraform searches AWS for an Ubuntu AMI.

---

## most_recent

```hcl
most_recent = true
```

This tells Terraform:

> Select the newest matching AMI.

---

## owners

```hcl
owners = ["099720109477"]
```

This is the AWS account ID associated with **Canonical**, the publisher of official Ubuntu AMIs.

Keep this value when searching for official Ubuntu images.

---

## AMI Name

```hcl
filter {
  name = "name"

  values = [
    "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
  ]
}
```

This searches for Ubuntu 24.04 server images.

The `*` means the remaining version/build information can vary.

---

## Architecture

```hcl
filter {
  name   = "architecture"
  values = ["x86_64"]
}
```

This selects the x86_64 architecture.

---

## Virtualization

```hcl
filter {
  name   = "virtualization-type"
  values = ["hvm"]
}
```

This selects HVM virtualization.

---

# 9. Why use an AMI Data Source?

Avoid hardcoding:

```hcl
ami = "ami-xxxxxxxx"
```

AMI IDs are region-specific.

For example:

```text
us-east-1
ami-xxxxxxxx

ap-south-1
ami-yyyyyyyy
```

Instead:

```hcl
ami = data.aws_ami.ubuntu.id
```

Terraform finds the appropriate matching AMI in the configured AWS region.

---

# 10. Key Pair

```hcl
resource "aws_key_pair" "my_key" {

  key_name   = var.key_name
  public_key = file(var.public_key_path)
}
```

Terraform uploads the public SSH key to AWS.

Example:

```text
rakesh-key-ec2
rakesh-key-ec2.pub
```

The public key:

```text
rakesh-key-ec2.pub
```

is provided to AWS.

The private key:

```text
rakesh-key-ec2
```

must remain protected.

---

# 11. Default VPC

```hcl
resource "aws_default_vpc" "default" {
}
```

This manages the AWS default VPC.

The VPC ID is then referenced using:

```hcl
aws_default_vpc.default.id
```

This is an example of Terraform **resource interpolation/reference**.

---

# 12. Security Group

```hcl
resource "aws_security_group" "my_security_group"
```

The Security Group controls network access to the EC2 instance.

### SSH

```hcl
ingress {
  from_port = var.ssh_port
  to_port   = var.ssh_port
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}
```

Allows SSH on port 22.

### HTTP

```hcl
ingress {
  from_port = var.http_port
  to_port   = var.http_port
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"]
}
```

Allows HTTP on port 80.

### Outbound

```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Allows outbound traffic.

---

# 13. Security Warning

For learning:

```hcl
cidr_blocks = ["0.0.0.0/0"]
```

is acceptable.

In production, avoid opening SSH to the entire internet.

Instead use a trusted corporate IP:

```hcl
cidr_blocks = ["YOUR_COMPANY_PUBLIC_IP/32"]
```

Better enterprise architectures may use:

```text
Internet
   |
   v
Load Balancer
   |
   v
Private EC2
   |
   v
Bastion / SSM
```

or preferably AWS Systems Manager Session Manager to avoid exposing SSH publicly.

---

# 14. EC2 Instance

```hcl
resource "aws_instance" "my_instance"
```

This creates the EC2 instance.

---

## AMI

```hcl
ami = data.aws_ami.ubuntu.id
```

Terraform dynamically gets the Ubuntu AMI.

---

## Instance Type

```hcl
instance_type = var.instance_type
```

The value comes from:

```text
terraform.tfvars
```

---

## Key Pair

```hcl
key_name = aws_key_pair.my_key.key_name
```

Terraform automatically understands that the EC2 depends on the key pair.

---

# 15. Terraform Dependency

This:

```hcl
key_name = aws_key_pair.my_key.key_name
```

creates an implicit dependency.

Terraform understands:

```text
Key Pair
   |
   v
EC2
```

Similarly:

```hcl
vpc_security_group_ids = [
  aws_security_group.my_security_group.id
]
```

creates:

```text
Security Group
      |
      v
     EC2
```

Terraform builds the dependency graph automatically.

---

# 16. EBS Root Volume

```hcl
root_block_device {

  volume_size = var.root_volume_size

  volume_type = var.root_volume_type
}
```

Our variables specify:

```text
Volume Size = 15 GB
Volume Type = GP3
```

GP3 is a general-purpose SSD volume type.

---

# 17. variables.tf

Variables make Terraform code reusable.

Create:

```hcl
variable "instance_type" {

  description = "EC2 instance type"

  type = string

  default = "t2.micro"
}


variable "key_name" {

  description = "AWS EC2 key pair name"

  type = string
}


variable "public_key_path" {

  description = "Path to public SSH key"

  type = string
}


variable "security_group_name" {

  description = "Security group name"

  type = string

  default = "automate-sg"
}


variable "ssh_port" {

  description = "SSH port"

  type = number

  default = 22
}


variable "http_port" {

  description = "HTTP port"

  type = number

  default = 80
}


variable "root_volume_size" {

  description = "Root EBS volume size in GB"

  type = number

  default = 15
}


variable "root_volume_type" {

  description = "Root EBS volume type"

  type = string

  default = "gp3"
}


variable "instance_name" {

  description = "EC2 instance name"

  type = string

  default = "buildserver"
}


variable "security_group_tag" {

  description = "Security group Name tag"

  type = string

  default = "auto-sg"
}
```

---

# 18. Why variables?

Without variables:

```hcl
instance_type = "t2.micro"
```

With variables:

```hcl
instance_type = var.instance_type
```

Now the same Terraform code can be reused.

Example:

```text
DEV
t2.micro

QA
t3.micro

PROD
t3.large
```

The infrastructure code doesn't need to be rewritten.

---

# 19. terraform.tfvars

This file contains actual values.

```hcl
instance_type = "t2.micro"

key_name = "rakesh-key-ec2"

public_key_path = "rakesh-key-ec2.pub"

security_group_name = "automate-sg"

ssh_port = 22

http_port = 80

root_volume_size = 15

root_volume_type = "gp3"

instance_name = "buildserver"

security_group_tag = "auto-sg"
```

---

# 20. Variable Flow

The Terraform variable flow is:

```text
terraform.tfvars
       |
       v
variables.tf
       |
       v
     var.*
       |
       v
     main.tf
       |
       v
AWS Resource
```

Example:

```text
terraform.tfvars

instance_type = "t2.micro"
        |
        v
variables.tf

variable "instance_type"
        |
        v
main.tf

instance_type = var.instance_type
        |
        v
AWS EC2
```

---

# 21. outputs.tf

Create:

```hcl
output "instance_id" {

  description = "EC2 instance ID"

  value = aws_instance.my_instance.id
}


output "public_ip" {

  description = "Public IP address of EC2 instance"

  value = aws_instance.my_instance.public_ip
}


output "public_dns" {

  description = "Public DNS name of EC2 instance"

  value = aws_instance.my_instance.public_dns
}


output "private_ip" {

  description = "Private IP address of EC2 instance"

  value = aws_instance.my_instance.private_ip
}


output "ami_id" {

  description = "Ubuntu AMI ID used by EC2"

  value = data.aws_ami.ubuntu.id
}


output "security_group_id" {

  description = "Security group ID"

  value = aws_security_group.my_security_group.id
}


output "key_pair_name" {

  description = "EC2 key pair name"

  value = aws_key_pair.my_key.key_name
}
```

---

# 22. Why outputs?

After Terraform creates the infrastructure, you may need important information.

For example:

```text
EC2 Instance ID
Public IP
Private IP
Public DNS
Security Group ID
AMI ID
```

Terraform outputs these values automatically.

Run:

```bash
terraform output
```

Example:

```text
instance_id = "i-xxxxxxxxxxxxxxxxx"

public_ip = "54.xx.xx.xx"

private_ip = "172.31.xx.xx"

public_dns = "ec2-54-xx-xx-xx.compute-1.amazonaws.com"

security_group_id = "sg-xxxxxxxxxxxxxxxxx"

key_pair_name = "rakesh-key-ec2"
```

---

# 23. Getting Individual Outputs

Public IP:

```bash
terraform output public_ip
```

Instance ID:

```bash
terraform output instance_id
```

Public DNS:

```bash
terraform output public_dns
```

AMI:

```bash
terraform output ami_id
```

---

# 24. Terraform Workflow

The standard Terraform workflow is:

```text
                  Terraform Code
                       |
                       v
                 terraform init
                       |
                       v
                terraform validate
                       |
                       v
                  terraform fmt
                       |
                       v
                  terraform plan
                       |
                       v
                 terraform apply
                       |
                       v
                AWS Infrastructure
```

---

# 25. Step 1 – Configure AWS CLI

Check AWS authentication:

```bash
aws sts get-caller-identity
```

Expected output contains:

```text
Account
Arn
UserId
```

Terraform needs valid AWS credentials.

---

# 26. Step 2 – Initialize Terraform

Run:

```bash
terraform init
```

This:

* Downloads AWS provider
* Initializes the working directory
* Creates `.terraform`
* Creates/updates provider dependency information

---

# 27. Step 3 – Format Code

Run:

```bash
terraform fmt
```

This formats Terraform files consistently.

---

# 28. Step 4 – Validate

Run:

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

This checks Terraform configuration syntax and structure.

---

# 29. Step 5 – Plan

Run:

```bash
terraform plan
```

Terraform compares:

```text
Terraform Configuration
        +
Terraform State
        +
Current AWS Infrastructure
        |
        v
Execution Plan
```

Example:

```text
Plan: 4 to add, 0 to change, 0 to destroy.
```

---

# 30. Step 6 – Apply

Run:

```bash
terraform apply
```

Terraform asks:

```text
Do you want to perform these actions?
Only 'yes' will be accepted.
```

Enter:

```text
yes
```

Terraform then creates:

```text
Key Pair
Security Group
EC2 Instance
EBS Volume
```

---

# 31. Verify Infrastructure

Check EC2:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]' \
  --output table
```

Check Terraform:

```bash
terraform output
```

---

# 32. Connect to EC2

After obtaining the public IP:

```bash
terraform output public_ip
```

SSH:

```bash
ssh -i rakesh-key-ec2 ubuntu@<PUBLIC-IP>
```

Example:

```bash
ssh -i rakesh-key-ec2 ubuntu@54.xx.xx.xx
```

---

# 33. Install Application

Once connected:

```bash
sudo apt update
```

For example, install Nginx:

```bash
sudo apt install nginx -y
```

Check:

```bash
systemctl status nginx
```

Because port 80 is open in the Security Group, the web server can receive HTTP traffic.

---

# 34. Real-Time Application Flow

```text
                    Internet User
                          |
                          |
                       HTTP :80
                          |
                          v
                  Security Group
                          |
                          v
                    EC2 Ubuntu
                          |
                          v
                       Nginx
                          |
                          v
                    Application
```

SSH administration:

```text
DevOps Engineer
       |
       | SSH :22
       v
Security Group
       |
       v
EC2 Ubuntu
```

---

# 35. Terraform State

Terraform maintains infrastructure state in:

```text
terraform.tfstate
```

The state tells Terraform what infrastructure it manages.

Conceptually:

```text
Terraform Code
      |
      v
Terraform State
      |
      v
AWS Infrastructure
```

Terraform uses state to determine what changed.

---

# 36. Enterprise Terraform State

For learning, local state is acceptable:

```text
terraform.tfstate
```

For enterprise environments, do not keep important production state only on a developer laptop.

A common AWS architecture is:

```text
Terraform
    |
    v
S3 Backend
    |
    +---- terraform.tfstate
    |
    v
DynamoDB / locking mechanism
```

Modern Terraform designs may use the locking capabilities supported by the selected backend/version.

The important enterprise concepts are:

* Remote state
* State locking
* Encryption
* Access control
* Versioning
* Backup/recovery

---

# 37. Enterprise Repository

A more realistic repository can eventually look like:

```text
terraform-aws-infrastructure/
│
├── environments/
│   │
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   │
│   ├── qa/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── outputs.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
│
├── modules/
│   │
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/
│   ├── security-group/
│   └── iam/
│
├── backend.tf
├── versions.tf
├── README.md
└── .gitignore
```

---

# 38. Enterprise Architecture with Modules

```text
                    Git Repository
                          |
                          v
                 Terraform Environment
                          |
             +------------+------------+
             |            |            |
             v            v            v
            DEV           QA          PROD
             |            |            |
             +------------+------------+
                          |
                          v
                     Terraform
                          |
              +-----------+-----------+
              |           |           |
              v           v           v
             VPC         IAM       Security Group
                                      |
                                      v
                                     EC2
                                      |
                                      v
                                     EBS
```

Modules provide reusable infrastructure components.

---

# 39. Why Modules?

Suppose the company has:

```text
20 applications
```

Each application needs:

* EC2
* Security Group
* IAM Role
* EBS

Instead of writing the same code 20 times, create:

```text
modules/ec2
```

Then reuse it:

```text
Application A → EC2 module
Application B → EC2 module
Application C → EC2 module
```

This follows the DRY principle:

> Don't Repeat Yourself.

---

# 40. Production CI/CD Architecture

In a real DevOps organization, engineers generally should not manually run:

```bash
terraform apply
```

against production from their laptop.

A more mature flow is:

```text
Developer
   |
   v
Git Push
   |
   v
Pull Request
   |
   v
Terraform CI Pipeline
   |
   +---- terraform fmt
   |
   +---- terraform validate
   |
   +---- terraform plan
   |
   +---- Security Scan
   |
   v
Code Review
   |
   v
Approval
   |
   v
Terraform Apply
   |
   v
AWS
```

---

# 41. Terraform + Jenkins Example

A DevOps organization may use Jenkins:

```text
GitHub
   |
   v
Jenkins
   |
   +---- Checkout
   |
   +---- Terraform Init
   |
   +---- Terraform Validate
   |
   +---- Terraform Plan
   |
   +---- Approval
   |
   +---- Terraform Apply
   |
   v
AWS
```

This provides:

* Automation
* Auditability
* Consistency
* Approval process
* Controlled deployments

---

# 42. Enterprise Security

Never commit private keys:

```text
rakesh-key-ec2
```

to GitHub.

Never commit secrets such as:

```text
password
AWS access key
AWS secret key
database password
API token
```

Use:

```text
AWS IAM
AWS Secrets Manager
AWS Systems Manager Parameter Store
Jenkins Credentials
OIDC
```

where appropriate.

---

# 43. .gitignore

Create:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
*.pem
rakesh-key-ec2
crash.log
```

However, if a `.tfvars` file contains only non-sensitive demo values, you may choose to commit a sanitized example such as:

```text
terraform.tfvars.example
```

Production secrets should never be committed.

---

# 44. Better Enterprise Variable Strategy

Instead of committing production secrets:

```text
terraform.tfvars
```

use environment-specific configuration.

Example:

```text
dev.tfvars
qa.tfvars
prod.tfvars
```

Then:

```bash
terraform plan -var-file="dev.tfvars"
```

or:

```bash
terraform plan -var-file="prod.tfvars"
```

This allows the same Terraform code to support multiple environments.

---

# 45. Environment Architecture

```text
                  Terraform Modules
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
         DEV             QA            PROD
          |              |              |
       t2.micro        t3.micro       t3.large
          |              |              |
          v              v              v
        AWS            AWS            AWS
```

Same infrastructure logic.

Different configuration.

---

# 46. Terraform Plan vs Apply

### terraform plan

```bash
terraform plan
```

Answers:

> What will Terraform change?

It does not normally create the infrastructure.

### terraform apply

```bash
terraform apply
```

Answers:

> Apply the planned infrastructure changes.

---

# 47. Terraform Destroy

To remove the infrastructure:

```bash
terraform destroy
```

Terraform will ask for confirmation.

```text
Plan: 0 to add, 0 to change, X to destroy.
```

For a lab environment:

```bash
terraform destroy
```

is useful for avoiding unnecessary AWS charges.

---

# 48. Troubleshooting

## Problem 1 – AMI Not Found

Error:

```text
InvalidAMIID.NotFound
```

Check:

```bash
aws ec2 describe-images \
  --image-ids <AMI-ID> \
  --region us-east-1
```

Using the data source approach reduces the risk of hardcoded region-specific AMI IDs.

---

## Problem 2 – Public Key Not Found

Error:

```text
Invalid function argument
```

Check:

```bash
ls -l rakesh-key-ec2.pub
```

Your Terraform must reference the correct path:

```hcl
public_key = file(var.public_key_path)
```

---

## Problem 3 – AWS Authentication

Check:

```bash
aws sts get-caller-identity
```

If authentication fails, configure your AWS credentials or use an appropriate IAM role.

---

## Problem 4 – EC2 Cannot Be Reached

Check:

```bash
terraform output public_ip
```

Then verify:

```text
Security Group
Port 22
Port 80
Public IP
Route
Subnet
Internet Gateway
```

---

## Problem 5 – SSH Permission Denied

Check private key permissions:

```bash
chmod 400 rakesh-key-ec2
```

Then:

```bash
ssh -i rakesh-key-ec2 ubuntu@<PUBLIC-IP>
```

---

# 49. Important Terraform Commands

### Initialize

```bash
terraform init
```

### Format

```bash
terraform fmt
```

### Validate

```bash
terraform validate
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

### Show state

```bash
terraform show
```

### List resources

```bash
terraform state list
```

### Show output

```bash
terraform output
```

### Destroy

```bash
terraform destroy
```

---

# 50. Complete Deployment Flow

Run:

```bash
aws sts get-caller-identity
```

Then:

```bash
terraform init
```

Then:

```bash
terraform fmt
```

Then:

```bash
terraform validate
```

Then:

```bash
terraform plan
```

Then:

```bash
terraform apply
```

Enter:

```text
yes
```

Then:

```bash
terraform output
```

Get the IP:

```bash
terraform output public_ip
```

Connect:

```bash
ssh -i rakesh-key-ec2 ubuntu@<PUBLIC-IP>
```

---

# 51. Enterprise Best Practices

Follow these practices when moving from lab to production:

### 1. Use Remote State

Use a secure remote backend.

### 2. Use Modules

Create reusable:

```text
VPC
EC2
Security Group
IAM
EKS
RDS
```

modules.

### 3. Use Environment Separation

Maintain:

```text
dev
qa
prod
```

configuration.

### 4. Use Git

Terraform code should be version controlled.

### 5. Use Pull Requests

Production infrastructure changes should go through review.

### 6. Use CI/CD

Run Terraform validation and plan automatically.

### 7. Restrict IAM

Do not give developers unnecessary administrator permissions.

### 8. Protect Secrets

Use:

```text
Secrets Manager
SSM Parameter Store
Jenkins Credentials
OIDC
```

### 9. Avoid Public SSH

Prefer:

```text
AWS Systems Manager Session Manager
```

or a controlled administrative path.

### 10. Tag Resources

Example:

```hcl
tags = {
  Name        = "buildserver"
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "Infrastructure"
}
```

---

# 52. Interview Explanation

If an interviewer asks:

> "Explain your Terraform EC2 project."

You can answer:

> "I created an AWS EC2 infrastructure using Terraform. I separated the configuration into main.tf, variables.tf, terraform.tfvars, outputs.tf, and provider.tf. I used an AWS AMI data source to dynamically identify the latest Ubuntu AMI, created a key pair and security group, and provisioned an EC2 instance with a GP3 root volume. Variables make the infrastructure reusable across environments, while outputs expose important values such as the EC2 public IP and instance ID. In an enterprise environment, I would extend this by using modules, remote state, CI/CD, IAM least privilege, environment separation, and pull-request based infrastructure changes."

---

# 53. Interview Questions

## Q1. What is Terraform?

Terraform is an Infrastructure as Code tool used to provision and manage infrastructure using declarative configuration.

---

## Q2. What is a Terraform resource?

A resource represents infrastructure Terraform creates or manages.

Example:

```hcl
resource "aws_instance" "my_instance" {
}
```

---

## Q3. What is a data source?

A data source retrieves existing information.

Example:

```hcl
data "aws_ami" "ubuntu" {
}
```

---

## Q4. Why did you use `aws_ami` data source?

To dynamically identify a matching Ubuntu AMI instead of hardcoding a region-specific AMI ID.

---

## Q5. What is variables.tf?

It declares Terraform variables and their types, descriptions, and optional defaults.

---

## Q6. What is terraform.tfvars?

It provides actual values for Terraform variables.

---

## Q7. What is outputs.tf?

It defines values Terraform should display after infrastructure creation.

---

## Q8. What is Terraform state?

Terraform state maintains information about infrastructure Terraform manages and helps Terraform determine changes.

---

## Q9. Why use remote state in production?

Remote state provides centralized storage, controlled access, collaboration, and appropriate state-locking/versioning capabilities.

---

## Q10. What is a Terraform module?

A module is a reusable collection of Terraform resources.

---

# 54. Final Architecture

The learning architecture:

```text
                        Git Repository
                              |
                              v
                    Terraform Configuration
                              |
       +----------------------+----------------------+
       |                      |                      |
       v                      v                      v
    main.tf             variables.tf          terraform.tfvars
       |                      |                      |
       +----------------------+----------------------+
                              |
                              v
                         outputs.tf
                              |
                              v
                    Terraform CLI / CI-CD
                              |
                     +--------+--------+
                     |                 |
                     v                 v
                  DEV/QA             PROD
                     |                 |
                     +--------+--------+
                              |
                              v
                            AWS
                              |
             +----------------+----------------+
             |                |                |
             v                v                v
         Default VPC     Security Group     Key Pair
                              |
                              v
                         EC2 Instance
                              |
                              v
                         Ubuntu 24.04
                              |
                              v
                           EBS GP3
```

---

# 55. What You Learned

After completing this project, you should understand:

```text
Terraform
   |
   +-- Provider
   |
   +-- Resource
   |
   +-- Data Source
   |
   +-- Variables
   |
   +-- tfvars
   |
   +-- Outputs
   |
   +-- References
   |
   +-- Dependencies
   |
   +-- Terraform State
   |
   +-- Plan
   |
   +-- Apply
   |
   +-- Destroy
   |
   +-- Modules
   |
   +-- Environment Separation
   |
   +-- Remote State
   |
   +-- CI/CD
```

This EC2 example is the **foundation**. The same Terraform concepts can then be extended to enterprise infrastructure such as:

```text
VPC
   ↓
Subnets
   ↓
Internet Gateway
   ↓
NAT Gateway
   ↓
Route Tables
   ↓
Security Groups
   ↓
IAM
   ↓
EC2
   ↓
ALB
   ↓
Auto Scaling
   ↓
RDS
   ↓
EKS
```

---

# 56. Cleanup

When the lab is complete:

```bash
terraform destroy
```

Confirm:

```text
yes
```

Then verify the resources have been removed.

```bash
terraform state list
```

For a completely destroyed stack, Terraform should no longer have managed resources in the state.

---

# 57. Final Enterprise Mindset

The important DevOps mindset is:

```text
Don't think:

"I created one EC2 using Terraform."

Think:

"I created reusable Infrastructure as Code that can
be version-controlled, reviewed, validated, automated,
and reused across multiple environments."
```

That is the difference between a **Terraform lab** and an **enterprise Terraform implementation**.
