resource "aws_iam_policy" "this" {

  for_each = var.policies

  name = each.key

  description = try(

    each.value.description,

    null

  )

  path = try(

    each.value.path,

    "/"

  )

  policy = jsonencode(

    each.value.policy

  )

  tags = local.common_tags

}