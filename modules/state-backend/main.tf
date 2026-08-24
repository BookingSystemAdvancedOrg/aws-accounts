# Per-account Terraform state backend for the CUSTOMER'S OWN application
# IaC (not this repo's state). One bucket per dev/prod account, created by
# account-baseline alongside the GitHub OIDC role, so both land together
# the moment a customer is added to customers.tfvars.
#
# No DynamoDB lock table by design (bucket-only, per requirement). That
# means no state locking unless the customer's own Terraform is >=1.11 and
# opts into the S3 backend's native lockfile (`use_lockfile = true`) --
# below that version, concurrent applies against the same state can
# corrupt it silently. Worth confirming that's an accepted tradeoff, or
# pinning the customer pipelines to >=1.11 with use_lockfile on.

resource "aws_s3_bucket" "tfstate" {
  # Account ID makes this globally unique without a random suffix, and keeps
  # the name deterministic across applies/imports.
  bucket = "${var.customer}-${var.env}-tfstate-${var.target_account_id}"

  # Never let a stray destroy on this stack take the customer's app state
  # with it. Same posture as aws_organizations_account in modules/organizations.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# State files are sensitive (may contain secrets/ARNs) but not throwaway --
# keep old versions around for a bounded window instead of forever.
resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    # Provider now requires exactly one of filter/prefix even to mean "apply
    # to the whole bucket" -- an empty filter is how you say that. Omitting
    # it works today but is a deprecation warning that becomes a hard error
    # in a future provider version.
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}

data "aws_iam_policy_document" "tfstate" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.tfstate.arn, "${aws_s3_bucket.tfstate.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.tfstate.json
}
