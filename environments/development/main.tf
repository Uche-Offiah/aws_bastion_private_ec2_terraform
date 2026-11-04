module "networking" {
  source = "../../modules/networking"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  admin_cidr   = var.admin_cidr
}

module "compute" {
  source = "../../modules/compute"

  project_name              = var.project_name
  bastion_subnet_id         = module.networking.public_subnet_id
  private_subnet_id         = module.networking.private_subnet_id
  bastion_security_group_id = module.security.bastion_security_group_id
  private_security_group_id = module.security.private_security_group_id
  bastion_instance_type     = var.bastion_instance_type
  private_instance_type     = var.private_instance_type
  key_pair_name             = var.key_pair_name
}

module "flow_logs" {
  source = "../../modules/flow-logs"

  project_name            = var.project_name
  aws_region              = var.aws_region
  vpc_id                  = module.networking.vpc_id
  flow_log_retention_days = var.flow_log_retention_days
}
