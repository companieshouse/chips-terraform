
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

  ingress_with_cidr_blocks = [
    {
      from_port   = 1521
      to_port     = 1522
      protocol    = "tcp"
      description = "Oracle DB port"
      cidr_blocks = join(",", concat(local.oracle_allowed_ranges, local.onprem_app_cidrs))
    },
    {
      from_port   = 1521
      to_port     = 1522
      protocol    = "tcp"
      description = "Oracle DB port"
      cidr_blocks = local.chs_subnet_data["mm-platform-applications-eu-west-2a"]
    },
    {
      from_port   = 1521
      to_port     = 1522
      protocol    = "tcp"
      description = "Oracle DB port"
      cidr_blocks = local.chs_subnet_data["mm-platform-applications-eu-west-2b"]
    },
    {
      from_port   = 1521
      to_port     = 1522
      protocol    = "tcp"
      description = "Oracle DB port"
      cidr_blocks = local.chs_subnet_data["mm-platform-applications-eu-west-2c"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH ports"
      cidr_blocks = join(",", local.ssh_allowed_ranges)
    }
  ]

  ingress_with_source_security_group_id = [for group in local.source_security_group_id :
    {
      from_port                = 1521
      to_port                  = 1522
      protocol                 = "tcp"
      description              = "Oracle DB CHIPS Security Group"
      source_security_group_id = group
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
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs.arn
  }

  tags = merge(
    local.default_tags,
    tomap({
      "Name"        = format("%s-db-%02d", var.application, count.index + 1)
      "Domain"      = local.internal_fqdn,
      "UNQNAME"     = var.oracle_unqname,
      "SID"         = var.oracle_sid,
      "ServiceTeam" = "Platforms/DBA",
      "Terraform"   = true
    })
  )

  lifecycle {
    ignore_changes = [
      user_data,
      user_data_base64
    ]
  }
}

  resource "aws_ebs_volume" "u-drive" {
  availability_zone = "eu-west-2a"
  size = 256
  type = "gp3"
  encrypted = true

  tags = {
    Name = "oltp-logical-standby"
  }
    depends_on = [
    aws_instance.db_ec2
  ]
}

resource "aws_volume_attachment" "ebs_attach" {
  count = var.db_instance_count

  device_name = "/dev/xvds"
  volume_id   = aws_ebs_volume.u-drive.id
  instance_id = aws_instance.db_ec2[count.index].id

}

resource "aws_route53_record" "db_dns" {
  count = var.db_instance_count

  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s-db-%02d", var.application, count.index + 1)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.db_ec2[count.index].private_ip]
}

resource "aws_route53_record" "dns_cname" {
  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s-db", var.application)
  type    = "CNAME"
  ttl     = "300"
  records = [format("%s-db-01.%s", var.application, local.internal_fqdn)]
  lifecycle {
    #Ignore changes to the record value, this may be changed outside of terraform 
    ignore_changes = [records]
  }
}
