output "notes_ip" {
  description = "Public address of the Notes service"
  value       = aws_instance.web[0].public_ip
}
