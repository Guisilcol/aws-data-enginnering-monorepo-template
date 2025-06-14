module "step_functions" {
  source = "./modules/stepfunctions"

  definitions_directory = "${path.module}/definitions/stepfunctions"
  role_arn              = module.master_role.role_arn

  depends_on = [ module.master_role ]
}