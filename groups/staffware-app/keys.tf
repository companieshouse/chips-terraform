# ------------------------------------------------------------------------------
# EWF Key Pair
# ------------------------------------------------------------------------------

resource "aws_key_pair" "iprocess_app_keypair" {
  key_name   = var.application
  public_key = local.staffware_app_ec2_data["public-key"]
}
