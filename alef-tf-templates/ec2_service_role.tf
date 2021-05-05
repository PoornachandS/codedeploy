data "aws_iam_policy" "ssm_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ec2-service-role" {
    name = "Ec2ServiceRole"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
   inline_policy {
    name = "ec2_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["s3:Get*","s3:List*"],
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
   }
}

resource "aws_iam_role_policy_attachment" "ec2-role-policy-attach" {
  role       = aws_iam_role.ec2-service-role.name
  policy_arn = data.aws_iam_policy.ssm_policy.arn
}
