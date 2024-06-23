variable "stop_time" {
  type        = string
  description = "Scheduled time to Stop instances (UTC)"
  default     = "cron(10 15 * * ? *)"
}

variable "start_time" {
  type        = string
  description = "Scheduled time to Start instances (UTC)"
  default     = "cron(20 15 * * ? *)"
}