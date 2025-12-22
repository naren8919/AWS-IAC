resource "random_id" "rand" {
  byte_length = 8

}

resource "aws_s3_bucket" "logs" {
  bucket = "ec2-logs-${random_id.rand.hex}"
}