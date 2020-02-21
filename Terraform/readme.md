# Terraform

## Versioning

You can use tfenv (installed via brew) to manage the version of terraform.

Install a specific version: `tfenv install 0.12.21`

## Quick Start

### Providers

This is defined in the `providers.tf` file and defines what provider you're wishing to use.

### Initialise

This will scan through the *.tf files and pull down any modules needed, and put them in the .terraform folder

`terraform init`

### Plan

This will produce the `terraform.tfstate.backup` file and create a summary of the changes your definitions will make.

`terraform plan`

### Apply

This will apply the changes against the provider you've defined.

`terraform apply`

### Destroy

This will remove all the resources defined

`terraform destroy`