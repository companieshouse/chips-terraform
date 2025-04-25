locals {

    client_cidrs = values(data.vault_generic_secret.client_cidrs.data)

}
