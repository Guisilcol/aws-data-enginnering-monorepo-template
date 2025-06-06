module "iam_roles" {
  source = "./modules/roles"
  yamls_directory = "./definitions/roles"
  template_values = var.template_values
}
