resource "aws_s3_bucket_object" "www-dachs-dog-image" {
    bucket = "${aws_s3_bucket.www-dachs-dog.bucket}"
    key = "index.html"
    source = "files/dachshund-hard-hat-1.jpg"
    acl = "public-read"
    content_type = "image/jpeg"
}

resource "aws_s3_bucket_object" "dachs-concourse-config-file" {
    bucket = "${aws_s3_bucket.dachs-concourse-config.bucket}"
    key = "concourse.yml"
    source = "${path.cwd}/concourse.yml"
    acl = "private"
}