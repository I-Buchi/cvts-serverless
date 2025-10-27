resource "aws_dynamodb_table" "clinica_metadata_table" {
  name         = "clinica-metadata-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "file_id"
  range_key    = "timestamp" # Added this line

  attribute {
    name = "file_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Name        = "ClinicaVoiceMetadata"
    Environment = "prod"
  }
}

