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
    name => "ssh -i ~/.ssh/kijanikiosk-key.pem ubuntu@${server.public_ip}"
  }
}