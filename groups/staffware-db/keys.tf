# ------------------------------------------------------------------------------
# EWF Key Pair
# ------------------------------------------------------------------------------

resource "aws_key_pair" "ec2_keypair" {
  key_name   = format("%s-db", var.application)
  public_key = local.ec2_data["public-key"]
}
