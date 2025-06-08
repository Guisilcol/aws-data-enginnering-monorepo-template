module "step_functions" {
  source = "./modules/stepfunctions"
  yamls_directory = "./definitions/stepfunctions"
  template_variables = {}
}