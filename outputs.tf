output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}
output "public_ip" {
  description = "Public IPv4 address"
  value       = aws_instance.web.public_ip
}
output "website_url" {
  description = "Nginx demo URL (when HTTP is enabled)"
  value       = var.enable_http ? "http://${aws_instance.web.public_ip}" : null
}
output "ssm_start_session" {
  description = "AWS CLI command to connect using Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
}
output "ssh_command" {
  description = "SSH command template if an EC2 key pair is configured"
  value       = var.key_name != null && var.ssh_cidr != null ? "ssh -i /path/to/private-key.pem ec2-user@${aws_instance.web.public_ip}" : null
}
