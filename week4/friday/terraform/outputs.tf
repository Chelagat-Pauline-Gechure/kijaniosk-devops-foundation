output "server_public_ips" {
  description = "Public IP addresses of all KijaniKiosk app servers"
  value = {
    for name, server in module.app_servers :
    name => server.public_ip
  }
}

output "ssh_commands" {
  description = "SSH commands for all app servers"
  value = {
    for name, server in module.app_servers :
    name => "ssh -i ~/.ssh/kijanikiosk-aws.pem ubuntu@${server.public_ip}"
  }
}

output "api_server_ip" {
  description = "Public IP of the API server"
  value       = module.app_servers["api"].public_ip
}

output "payments_server_ip" {
  description = "Public IP of the payments server"
  value       = module.app_servers["payments"].public_ip
}

output "logs_server_ip" {
  description = "Public IP of the logs server"
  value       = module.app_servers["logs"].public_ip
}
