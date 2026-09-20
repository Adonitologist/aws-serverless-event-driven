module "messaging" {
  source      = "./modules/messaging"
  environment = var.environment
  
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
}

module "api_eventbridge" {
  source        = "./modules/api_eventbridge"
  environment   = var.environment
  sns_topic_arn = module.messaging.sns_topic_arn
}

module "compute_storage" {
  source              = "./modules/compute_storage"
  environment         = var.environment
  sqs_queue_arn       = module.messaging.sqs_main_queue_arn
  kms_key_arn         = module.messaging.kms_key_arn
  replica_kms_key_arn = module.messaging.kms_replica_key_arn
  secondary_region    = var.secondary_region
}

module "networking_dr" {
  source       = "./modules/networking_dr"
  environment  = var.environment
  api_endpoint = module.api_eventbridge.api_endpoint
}

module "api_eventbridge" {
  source        = "./modules/api_eventbridge"
  environment   = var.environment
  sns_topic_arn = module.messaging.sns_topic_arn
  api_route_key = var.api_route_key
}

module "compute_storage" {
  source                = "./modules/compute_storage"
  environment           = var.environment
  sqs_queue_arn         = module.messaging.sqs_main_queue_arn
  kms_key_arn           = module.messaging.kms_key_arn
  replica_kms_key_arn   = module.messaging.kms_replica_key_arn
  secondary_region      = var.secondary_region
  lambda_runtime        = var.lambda_runtime
  lambda_memory_size    = var.lambda_memory_size
  lambda_timeout        = var.lambda_timeout
  dynamodb_billing_mode = var.dynamodb_billing_mode
}