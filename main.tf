# -------------------------------
# AWS Lambda Role
# -------------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "clinica_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

# -------------------------------
# Attach policy for CloudWatch and S3 access
# -------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# -------------------------------
# Lambda Function
# -------------------------------
resource "aws_lambda_function" "clinica_lambda" {
  function_name = "clinica-voice-processor"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = "lambda.zip"
  timeout       = 10
  memory_size   = 128

  environment {
    variables = {
      STAGE = "prod"
    }
  }
}

resource "aws_lambda_function" "clinica_comprehend_lambda" {
  function_name = "clinica-comprehend-medical"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_comprehend.lambda_handler"
  runtime       = "python3.9"
  filename      = "lambda_comprehend.zip"
  timeout       = 60

  environment {
    variables = {
      REGION = "us-east-1"
    }
  }
}

resource "aws_iam_policy_attachment" "comprehend_basic_policy" {
  name       = "comprehend-basic-policy"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/ComprehendFullAccess"
}

resource "aws_iam_policy_attachment" "comprehend_s3_policy" {
  name       = "comprehend-s3-policy"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# ---------------------------------------
# S3 Trigger for Comprehend Lambda
# ---------------------------------------
resource "aws_lambda_permission" "allow_s3_to_invoke_comprehend" {
  statement_id  = "AllowS3InvokeComprehend"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.clinica_comprehend_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.clinica_voice_bucket.arn
}

resource "aws_s3_bucket_notification" "trigger_comprehend_lambda" {
  bucket = aws_s3_bucket.clinica_voice_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.clinica_comprehend_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json" # triggers only for JSON output files
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke_comprehend]
}

