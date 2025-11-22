provider "aws" {
  region = var.region
}

module "eks" {
  source              = "./modules/eks"
  cluster_name        = var.cluster_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
