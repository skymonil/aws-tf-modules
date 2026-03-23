# envs/prod/terraform.tfvars

region         = "ap-south-1"
environment    = "prod"
vpc_name       = "core-vpc"
vpc_cidr_block = "10.0.0.0/16"

# Here is our pristine Data Contract in action.
# Since it's prod, we deploy across 3 Availability Zones.
subnet_config = {
  
  "ap-south-1a" = {
    public_cidr  = "10.0.1.0/24"
    private_cidr = "10.0.11.0/24"
  }
  
  "ap-south-1b" = {
    public_cidr  = "10.0.2.0/24"
    private_cidr = "10.0.12.0/24"
  }
  
  "ap-south-1c" = {
    public_cidr  = "10.0.3.0/24"
    private_cidr = "10.0.13.0/24"
  }
}


