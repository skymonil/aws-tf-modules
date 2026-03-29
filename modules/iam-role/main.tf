resource "aws_iam_role" "this" {

  name = var.role.name

  description = try(var.role.description, null)

  assume_role_policy = jsonencode(

    var.role.assume_role_policy

  )

  path = var.role.path

  max_session_duration = var.role.max_session_duration

  tags = local.common_tags

}

resource "aws_iam_role_policy_attachment" "managed" {

  for_each = toset(

    var.role.managed_policy_arns

  )

  role = aws_iam_role.this.name

  policy_arn = each.value

}

resource "aws_iam_role_policy" "inline" {

  for_each = var.role.inline_policies

  name = each.key

  role = aws_iam_role.this.id

  policy = jsonencode(

    each.value.policy

  )

}