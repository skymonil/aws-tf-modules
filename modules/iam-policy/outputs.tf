output "policy_arns" {

  description = "Map of policy ARNs"

  value = {

    for k,v in aws_iam_policy.this :

    k => v.arn

  }

}

output "policy_ids" {

  description = "Map of policy IDs"

  value = {

    for k,v in aws_iam_policy.this :

    k => v.id

  }

}