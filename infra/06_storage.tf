module "buckets" {
    source = "./modules/buckets"
    yamls_directory = "./definitions/buckets"
    template_values = var.template_values
}