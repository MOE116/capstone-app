region              = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
public_subnet_a_cidr = "10.0.1.0/24"
public_subnet_b_cidr = "10.0.2.0/24"
instance_type       = "t2.micro"

# Replace with your real EC2 keypair name from AWS
key_name            = "capstonekey"

# Ubuntu Server 24.04 LTS (HVM) (update if region != us-east-1)
ami_id              = "ami-0360c520857e3138f"
