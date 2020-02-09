variable "project-common-name" {
  type    = string
  description = "GCP Project Common Name without the environment suffix"
}

variable "environment" {
  type    = string
  description = "The environment this project belongs to"
}
