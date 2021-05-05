# s3 bucket to store artifacts
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "pipeline-alef-artifactsbucket"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = data.aws_kms_key.by_alias.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

#codepipeline with source stage to github and deploy stage to code deploy
resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

    encryption_key {
      id   = data.aws_kms_key.by_alias.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = "arn:aws:codestar-connections:us-east-1:422649149203:connection/3ac0b3b9-c3dc-495f-b10d-fd6d6f7d7c3e"
        FullRepositoryId = "PoornachandS/codedeploy"
        BranchName       = "master"
      }
    }
 }

   stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
         ApplicationName = aws_codedeploy_app.alef-app.name
         DeploymentGroupName = aws_codedeploy_deployment_group.alef-deploy-group.id
       }
     }
   }
}

#code deploy application and deploymnet group
resource "aws_codedeploy_app" "alef-app" {
  compute_platform = "Server"
  name             = "MyDemoApplication"
}

resource "aws_codedeploy_deployment_group" "alef-deploy-group" {
  app_name              = aws_codedeploy_app.alef-app.name
  deployment_group_name = "MyDemoDeploymentGroup"
  service_role_arn      = aws_iam_role.cd-service-role.arn
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }
  autoscaling_groups = [aws_autoscaling_group.alef-group.name]
}

