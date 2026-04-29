variable "name" {
  type = string
}

variable "lambda_arn" {
  type = string
}

variable "batch_size" {
  type    = number
  default = 10
}

variable "batching_window" {
  type    = number
  default = 0
}

variable "max_concurrency" {
  type    = number
  default = 10
}

variable "visibility_timeout" {
  type    = number
  default = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}
