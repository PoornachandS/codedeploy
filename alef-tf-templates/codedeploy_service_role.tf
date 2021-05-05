data "aws_iam_policy" "CodeDeployPolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role" "cd-service-role" {
    name = "CodeDeployServiceRole"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy-role-policy-attach" {
  role       = aws_iam_role.cd-service-role.name
  policy_arn = data.aws_iam_policy.CodeDeployPolicy.arn
}
