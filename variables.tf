# Define the AWS region to operate in
variable "region" {
  default = "us-west-2"
}

# Specify an AMI override. If deploying to us-west-2, an AMI already exists
variable "ami" {
  default = null
}

