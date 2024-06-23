resource "aws_dynamodb_table" "stopinstance_table" {
  name           = "StopInstanceDBtable"
  billing_mode   = "PROVISIONED"
  hash_key       = "InstanceId"
  read_capacity  = 10
  write_capacity = 10

  attribute {
    name = "InstanceId"
    type = "S"
  }

  attribute {
    name = "Region"
    type = "S"
  }

  global_secondary_index {
    name            = "RegionIndex"
    hash_key        = "Region"
    projection_type = "KEYS_ONLY"
    read_capacity   = 5
    write_capacity  = 5
  }
}
