variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}
variable "project_name" {
  description = "Resource name prefix"
  type        = string
  default     = "ec2-basics-lab"
}
variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}
variable "ssh_cidr" {
  description = "Your public IPv4 address in CIDR notation, e.g. 203.0.113.10/32. SSH is disabled if null."
  type        = string
  default     = null
  validation {
    condition     = var.ssh_cidr == null ? true : can(cidrnetmask(var.ssh_cidr)) && endswith(var.ssh_cidr, "/32")
    error_message = "ssh_cidr must be a single IPv4 address with /32, or null."
  }
}
variable "key_name" {
  description = "Optional existing EC2 key pair name for SSH; use null for SSM-only access"
  type        = string
  default     = null
}
variable "enable_http" {
  description = "Allow inbound HTTP from the internet for the Nginx demo"
  type        = bool
  default     = true
}
