variable "state_s3_bucket" {
  type = "string"
}

resource "aws_s3_bucket" "state" {
  bucket = "${var.state_s3_bucket}"
  acl    = "private"
  versioning {
    enabled = true
  }
  force_destroy = false
}
