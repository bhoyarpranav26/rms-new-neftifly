data "aws_iam_policy_document" "s3_policy" {
  count = var.create_cloudfront ? 1 : 0
  statement {
    actions = ["s3:GetObject"]
    principals {
      type = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai[0].iam_arn]
    }
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  count = var.create_cloudfront ? 1 : 0
  comment = "OAI for ${var.project_name} frontend"
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  count  = var.create_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.s3_policy[0].json
}

resource "aws_cloudfront_distribution" "cdn" {
  count   = var.create_cloudfront ? 1 : 0
  enabled = true
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "s3-${aws_s3_bucket.frontend.id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai[0].cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD" ]
    cached_methods   = ["GET", "HEAD" ]
    target_origin_id = "s3-${aws_s3_bucket.frontend.id}"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-cdn"
  }
}

output "cloudfront_domain" {
  value = var.create_cloudfront ? aws_cloudfront_distribution.cdn[0].domain_name : ""
}
