resource "aws_s3_bucket" "www-dachs-dog" {
    bucket = "www.dachs.dog"
    acl = "public-read"
    region = "eu-west-1"
    website {
        index_document = "index.html"
        error_document = "error.html"
    }
}

resource "aws_s3_bucket" "dachs-concourse-config" {
    bucket = "dachs-concourse-config"
    acl = "private"
    region = "eu-west-1"
    versioning {
        enabled = true
    }
}