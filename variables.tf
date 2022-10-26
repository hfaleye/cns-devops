variable "region" {
  description = "AWS Deployment region.."
  default = "us-east-1"
}

variable "namespace" {
  default = "cn"
}

variable "stage" {
  default = "dev"
}

variable "name" {
  default = "app"
}


variable "cidr_block" {
  default = "10.0.0.0/16"
}
