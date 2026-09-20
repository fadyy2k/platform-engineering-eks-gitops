module "platform" {
  source = "./modules/platform"

  project_name                   = var.project_name
  environment                    = var.environment
  vpc_cidr                       = var.vpc_cidr
  kubernetes_version             = var.kubernetes_version
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  node_instance_types            = var.node_instance_types
  node_desired_size              = var.node_desired_size
  node_min_size                  = var.node_min_size
  node_max_size                  = var.node_max_size
}
