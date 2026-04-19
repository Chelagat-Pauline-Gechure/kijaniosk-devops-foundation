output "instance_public_ip" {
  description = "Public IP address of the KijaniKiosk API server"
  value       = aws_instance.kk_api.public_ip  # or google_compute_instance.kk_api.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "SSH command to connect to the API server"
  value       = "ssh -i ~/.ssh/your-key ubuntu@${aws_instance.kk_api.public_ip}"
}