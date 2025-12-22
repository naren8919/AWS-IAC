resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated" {
  key_name_prefix = "${var.project}-key-"
  public_key      = tls_private_key.generated.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${path.module}/${var.project}_generated_key.pem"
  file_permission = "0600"
}

output "generated_key_name" {
  value       = aws_key_pair.generated.key_name
  description = "Name of the key pair created in AWS (when var.key_name is left blank)"
}

output "generated_private_key_path" {
  value       = local_file.private_key.filename
  description = "Local path where the generated private key PEM was saved"
  sensitive   = true
}

/*
Notes:
- If you leave `var.key_name` empty, Terraform will generate an RSA keypair, upload the public key to AWS
  (creating an `aws_key_pair`), and write the private key to `${path.module}/${var.project}_generated_key.pem`.
- This is convenient for demo/learning environments. The private key file is stored locally and is marked
  sensitive in outputs. Be careful with this file in production (state will contain the private key).
*/
