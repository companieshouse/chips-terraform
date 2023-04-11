
# ------------------------------------------------------------------------------
# EC2 Sec Group
# ------------------------------------------------------------------------------

  module "reginit_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "sgr-${var.application}-ec2-001"
  description = "Security group for the CHIPS Reginit EC2 instance"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  ingress_cidr_blocks = local.reginit_allowed_ranges
  ingress_rules       = ["oracle-db-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 1830
      to_port     = 1830
      protocol    = "tcp"
      description = "Agent port is unidirectional, OMS to Agent"
      cidr_blocks = join(",", local.reginit_allowed_ranges)
    },
    {
      from_port   = 3872
      to_port     = 3872
      protocol    = "tcp"
      description = "Agent port is unidirectional, OMS to Agent"
      cidr_blocks = join(",", local.reginit_allowed_ranges)
    },
    {
      from_port   = 1159
      to_port     = 1159
      protocol    = "tcp"
      description = "Agent or target host communication to OMS host, unidirectional, Agent to OMS"
      cidr_blocks = join(",", local.reginit_allowed_ranges)
    },
    {
      from_port   = 4889
      to_port     = 4889
      protocol    = "tcp"
      description = "Agent or target host communication to OMS host, unidirectional, Agent to OMS"
      cidr_blocks = join(",", local.reginit_allowed_ranges)
    },
    {
      from_port   = 7799
      to_port     = 7799
      protocol    = "tcp"
      description = "User browser host to OMS host through port 7799 for EM 13.5 console HTTPS access, unidirectional"
      cidr_blocks = join(",", local.reginit_allowed_ranges)
    },
    {
      from_port   = 7101
      to_port     = 7101
      protocol    = "tcp"
      description = "User browser host to OMS host for WebLogic Server Admin Console access through port 7101, unidirectional"
      cidr_blocks = join(",", local.reginit_allowed_ranges)
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "The OMS transfers Agent software to a target server in an Agent Push deployment through this standard OS SSH port, unidirectional"
      cidr_blocks = join(",", local.ssh_allowed_ranges)
    }
  ]

  egress_rules = ["all-all"]
}

# ------------------------------------------------------------------------------
# EC2
# ------------------------------------------------------------------------------
resource "aws_instance" "reginit_ec2" {
  count = var.instance_count

  ami = var.ami_id == null ? data.aws_ami.oracle_12.id : var.ami_id

  key_name      = aws_key_pair.ec2_keypair.key_name
  instance_type = var.instance_size
  subnet_id     = local.data_subnet_az_map[element(local.deployment_zones, count.index)]["id"]

  iam_instance_profile = module.reginit_instance_profile.aws_iam_instance_profile.name
  user_data_base64     = data.template_cloudinit_config.userdata_config[count.index].rendered

  vpc_security_group_ids = [
    module.reginit_security_group.this_security_group_id
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
    Name = "chips-reginit"
  }
    depends_on = [
    aws_instance.reginit_ec2
  ]
}

resource "aws_volume_attachment" "ebs_attach" {
  count = var.instance_count

  device_name = "/dev/xvds"
  volume_id   = aws_ebs_volume.u_drive.id
  instance_id = aws_instance.reginit_ec2[count.index].id

}

resource "aws_ebs_volume" "data" {
count = var.instance_count

availability_zone = aws_instance.reginit_ec2[count.index].availability_zone
encrypted = true
kms_key_id = data.aws_kms_key.ebs.arn
size = var.data_volume_size
type = var.data_volume_type

tags = {
  "Name" = format("%s-db-%02d-data", var.application, count.index + 1)
  }
}

resource "aws_volume_attachment" "data_attachment" {
count = var.instance_count

device_name = var.data_volume_device_name
instance_id = aws_instance.reginit_ec2[count.index].id
volume_id = aws_ebs_volume.data[count.index].id
}

resource "aws_route53_record" "reginit_dns" {
  count = var.instance_count

  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s-%02d", var.application, count.index + 1)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.reginit_ec2[count.index].private_ip]
}

