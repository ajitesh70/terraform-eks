variable "region" { type = string }

variable "cluster_name" {
  type    = string
  default = "my-eks-2"
}

variable "vpc_cidr" { type = string }

variable "public_subnet_cidrs" { type = list(string) }

variable "private_subnet_cidrs" { type = list(string) }
