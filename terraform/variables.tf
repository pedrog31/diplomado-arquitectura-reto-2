variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "modulo2-rust-api"
}

variable "ses_from_email" {
  type = string
}

variable "ses_to_email" {
  type = string
}
