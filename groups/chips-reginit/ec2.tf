# ------------------------------------------------------------------------------
# Security group rules
# ------------------------------------------------------------------------------

resource "aws_security_group" "reginit" {
  name        = "sgr-${var.application}-ec2-001"
  description = "Security group for the CHIPS Reginit EC2 instance"
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_security_group_rule" "reginit_ingress" {
  for_each = {
    for rule in var.reginit_ingress_rules : "${rule.protocol}_${rule.from_port}_${rule.to_port}" => rule
  }

  type              = "ingress"
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.reginit.id
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.vpn.id, data.aws_ec2_managed_prefix_list.on_premise.id]
}

resource "aws_security_group_rule" "Oracle_Management_Agent" {
  type                     = "ingress"
  description              = "Oracle Management Agent"
  from_port                = 3872
  to_port                  = 3872
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.oem.id
  security_group_id        = aws_security_group.reginit.id
}

resource "aws_security_group_rule" "Enterprise_Manager_Upload_Http_SSL" {
  type                     = "ingress"
  description              = "Oracle Management Agent"
  from_port                = 4903
  to_port                  = 4903
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.oem.id
  security_group_id        = aws_security_group.reginit.id
}

resource "aws_security_group_rule" "OEM_SSH" {
  type                     = "ingress"
  description              = "Oracle Management Agent"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.oem.id
  security_group_id        = aws_security_group.reginit.id
}

resource "aws_security_group_rule" "OEM_listener" {
  type                     = "ingress"
  description              = "Oracle listener"
  from_port                = 1521
  to_port                  = 1522
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.oem.id
  security_group_id        = aws_security_group.reginit.id
}

resource "aws_security_group_rule" "Egress" {
  type                     = "egress"
  description              = "egress traffic"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.reginit.id
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
    aws_security_group.reginit.id
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
      "Terraform"   = true,
      "Backup"      = "backup21"
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
  size              = 256
  type              = "gp3"
  encrypted         = true

  tags = {
    Name   = "chips-reginit"
    Backup = "backup21"
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
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs.arn
  size              = var.data_volume_size
  type              = var.data_volume_type

  tags = {
    "Name" = format("%s-db-%02d-data", var.application, count.index + 1)
  }
}

resource "aws_volume_attachment" "data_attachment" {
  count = var.instance_count

  device_name = var.data_volume_device_name
  instance_id = aws_instance.reginit_ec2[count.index].id
  volume_id   = aws_ebs_volume.data[count.index].id
}

resource "aws_route53_record" "reginit_dns" {
  count = var.instance_count

  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s-%02d", var.application, count.index + 1)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.reginit_ec2[count.index].private_ip]
}
