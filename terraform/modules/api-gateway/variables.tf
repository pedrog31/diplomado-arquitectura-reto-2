variable "name" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "sqs_queue_url" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "prod"
}

variable "rate_limit" {
  type    = number
  default = 15
}

variable "burst_limit" {
  type    = number
  default = 5000
}

variable "tags" {
  type    = map(string)
  default = {}
}
