
# ------------------------------------------------------------------------------
# EC2 Sec Group
# ------------------------------------------------------------------------------
module "db_ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "sgr-${var.application}-db-ec2-001"
  description = "Security group for the DB ec2 instance"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]
  ingress_with_source_security_group_id = [
    {
      from_port                = 1521
      to_port                  = 1521
      protocol                 = "tcp"
      description              = "iProcess Application Security Group"
      source_security_group_id = data.aws_security_group.iprocess_app.id
    }
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 1521
      to_port     = 1521
      protocol    = "tcp"
      description = "Oracle DB port"
      cidr_blocks = join(",", local.oracle_allowed_ranges)
    },
    {
      from_port   = 1522
      to_port     = 1522
      protocol    = "tcp"
      description = "Oracle DB port"
      cidr_blocks = join(",", local.oracle_allowed_ranges)
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH ports"
      cidr_blocks = join(",", local.ssh_allowed_ranges)
    }
  ]
  egress_rules = ["all-all"]
}

# ------------------------------------------------------------------------------
# EC2
# ------------------------------------------------------------------------------
resource "aws_instance" "db_ec2" {
  count = var.db_instance_count

  ami = var.ami_id == null ? data.aws_ami.oracle_12.id : var.ami_id

  key_name      = aws_key_pair.ec2_keypair.key_name
  instance_type = var.db_instance_size
  subnet_id     = local.data_subnet_az_map[element(local.deployment_zones, count.index)]["id"]

  iam_instance_profile = module.db_instance_profile.aws_iam_instance_profile.name
  user_data_base64     = data.template_cloudinit_config.userdata_config[count.index].rendered

  vpc_security_group_ids = [
    module.db_ec2_security_group.this_security_group_id
  ]

  root_block_device {
    volume_size = "200"
    volume_type = "gp2"
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs.arn
  }

  tags = merge(
    local.default_tags,
    tomap({
      "Name"        = format("%s-db-%02d", var.application, count.index + 1),
      "Domain"      = local.internal_fqdn,
      "ServiceTeam" = "Platforms/DBA",
      "Terraform"   = true
    })
  )
}

resource "aws_route53_record" "db_dns" {
  count = var.db_instance_count

  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s-db-%02d", var.application, count.index + 1)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.db_ec2[count.index].private_ip]
}