resource "aws_iam_user" "github_actions_user" {
  name          = "github-actions-user"
  path          = "/"
  force_destroy = true # Allows destroying user even if they have non-Terraform managed keys
}

resource "aws_iam_access_key" "github_actions_user_access_key" {
  user = aws_iam_user.github_actions_user.name
}
