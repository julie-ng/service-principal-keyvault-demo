# terraform-keyvault-demo

Infrastructure as Code example using [Terraform](https://terraform.io) to create an Azure Service Principal and store its credentials in Key Vault.

## Use Case

- Mass automation of creation of Service Principals a common use case for central IT teams.
- Advantage: save service principal password expiration in Key Vault to setup other automation to rotate secrets

### Why Terraform?

ARM templates cannot create service principals, which is an Azure AD resource. Instead of creating them with CLI and querying JSON outputs, we will just use Terraform.

## What Resources are Created?

This code example…

1. Creates an **[Azure Resource Group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview#understand-scope)**
2. Creates an **[Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/general/basic-concepts)**
   - give current ARM client access to manage secrets in the Key Vault (in order to save secrets)
3. Creates a new **[Azure Service Principal (SP)](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)**
     - store SP client ID in Key Vault
     - store SP client secret in Key Vault
     - scope SP to resource group

Note: a randomly generated suffix is included in resource names because Key Vault names must be globally unique.

| Resource | Name |
|:--|:--|
| Resource Group | `tf-kv-demo-e6vh-rg` |
| Service Principal | `tf-kv-demo-e6vh-rg-sp` |
| Key Vault | `tf-kv-demo-e6vh-kv` |

## How to use

### Login to Azure

This example is meant to be run locally. So first make sure you have logged into Azure:

```
az login
```

### Terraform

Initialize

```bash
terraform init
```

Run the `plan` command to see what resources Terraform will create:

```bash
terraform plan -out plan.tfplan
```

If you are satisfied with the plan, run it:

```bash
terraform apply plan.tfplan
```

### Verify Service Principal Secret was stored in Key Vault

First see which secret Terraform used for the service principal 

```bash
terraform output demo_secret
```

Then compare with the result in Key Vault, which should be the same:

```bash
az keyvault secret show \
    --name demo-secret \
    --vault $(terraform output key_vault_name | tr -d '"') | jq '.value'
```

Note that because this example creates random suffixes, we also need to ask Terraform for the key vault name.

### Clean Up

When you are finished, remove the example resources with the `destroy` command.

```bash
terraform destroy
```

