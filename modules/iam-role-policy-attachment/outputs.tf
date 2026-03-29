output "attached_policies" {

  description = "Policies attached to role"

  value = {

    for k,v in aws_iam_role_policy_attachment.this :

    k => v.policy_arn

  }

}