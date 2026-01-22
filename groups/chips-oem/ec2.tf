
# ------------------------------------------------------------------------------
# EC2 Sec Group
# ------------------------------------------------------------------------------

  module "oem_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0.0"

  name        = "sgr-${var.application}-ec2-001"
  description = "Security group for the CHIPS OEM EC2 instance"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  ingress_cidr_blocks = local.oem_allowed_ranges
  ingress_rules       = ["oracle-db-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 1159
      to_port     = 1159
      protocol    = "tcp"
      description = "Enterprise Manager Upload HTTPS"
      cidr_blocks = join(",", local.oem_allowed_ranges)
    },
    {
      from_port   = 4899
      to_port     = 4908
      protocol    = "tcp"
      description = "Enterprise Manager Upload HTTPS"
      cidr_blocks = join(",", local.oem_allowed_ranges, local.e5_oem)
    },
    {
      from_port   = 3872
      to_port     = 3872
      protocol    = "tcp"
      description = "Enterprise Manager Agent"
      cidr_blocks = join(",", local.oem_allowed_ranges, local.e5_oem)
    },
    {
      from_port   = 7799
      to_port     = 7809
      protocol    = "tcp"
      description = "Cloud Control Console HTTPS"
      cidr_blocks = join(",", local.oem_allowed_ranges, local.http_allowed_ranges)
    },
    {
      from_port   = 7101
      to_port     = 7200
      protocol    = "tcp"
      description = "WebLogic Admin Server HTTPS"
      cidr_blocks = join(",", local.oem_allowed_ranges)
    },
    {
      from_port   = 7301
      to_port     = 7400
      protocol    = "tcp"
      description = "Cloud Control Managed Server HTTPS"
      cidr_blocks = join(",", local.oem_allowed_ranges)
    },
    {
      from_port   = 7401
      to_port     = 7500
      protocol    = "tcp"
      description = "WebLogic Node Manager HTTPS"
      cidr_blocks = join(",", local.oem_allowed_ranges)
    },
    {
      from_port   = 3801
      to_port     = 3801
      protocol    = "tcp"
      description = "JVM Diagnostics Managed Server"
      cidr_blocks = join(",", local.oem_allowed_ranges)
    },
    {
      from_port   = 51099
      to_port     = 51099
      protocol    = "tcp"
      description = "RMI Registry"
      cidr_blocks = join(",", local.oem_allowed_ranges)
    },
    {
      from_port   = 5503
      to_port     = 5503
      protocol    = "tcp"
      description = "Java Provider"
      cidr_blocks = join(",", local.oem_allowed_ranges)
    },
    {
      from_port   = 55000
      to_port     = 55000
      protocol    = "tcp"
      description = "Remote Service Controller"
      cidr_blocks = join(",", local.oem_allowed_ranges)
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH ports"
      cidr_blocks = join(",", local.ssh_allowed_ranges, local.e5_oem)
    }
  ]

  egress_rules = ["all-all"]
}

# ------------------------------------------------------------------------------
# EC2
# ------------------------------------------------------------------------------
resource "aws_instance" "oem_ec2" {
  count = var.instance_count

  ami = var.ami_id == null ? data.aws_ami.oracle_12.id : var.ami_id

  key_name      = aws_key_pair.ec2_keypair.key_name
  instance_type = var.instance_size
  subnet_id     = local.data_subnet_az_map[element(local.deployment_zones, count.index)]["id"]

  iam_instance_profile = module.oem_instance_profile.aws_iam_instance_profile.name
  user_data_base64     = data.template_cloudinit_config.userdata_config[count.index].rendered

  vpc_security_group_ids = [
    module.oem_security_group.this_security_group_id
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
      "Name"        = format("%s-%02d", var.application, count.index + 1)
      "Domain"      = local.internal_fqdn,
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

resource "aws_ebs_volume" "u_drive" {
  availability_zone = "eu-west-2a"
  size = 256
  type = "gp3"
  encrypted = true

  tags = {
    Name = "chips-oem"
  }
    depends_on = [
    aws_instance.oem_ec2
  ]
}

resource "aws_volume_attachment" "ebs_attach" {
  count = var.instance_count

  device_name = "/dev/xvds"
  volume_id   = aws_ebs_volume.u_drive.id
  instance_id = aws_instance.oem_ec2[count.index].id

}

resource "aws_route53_record" "oem_dns" {
  count = var.instance_count

  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s-%02d", var.application, count.index + 1)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.oem_ec2[count.index].private_ip]
}
