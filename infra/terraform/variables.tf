variable "region" { 
  default = "us-east-1" 
  }
variable "vpc_cidr" {
   default = "10.0.0.0/16" 
  }

variable "public_subnet_a_cidr" { 
  default = "10.0.1.0/24" 
}
variable "public_subnet_b_cidr" { 
  default = "10.0.2.0/24" 
}
variable "key_name" { 
  description = "SSH keypair name in AWS" 
  type        = string
}
variable "ami_id" {
  description = "Ubuntu Server 24.04 LTS (HVM)(update per region)"
  default     = "ami-0360c520857e3138f" # us-east-1
}
variable "instance_type" {
  default = "t2.micro"
}