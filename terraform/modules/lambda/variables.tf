variable "name" {
  type = string
}

variable "source_dir" {
  description = "Path to the Rust Lambda project directory"
  type        = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "reserved_concurrent_executions" {
  type    = number
  default = -1
}

variable "environment_vars" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
