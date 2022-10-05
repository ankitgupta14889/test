# Terraformer

It's a CLI tool that generates `tf` and `tfstate` files based on the existing infrastructure.


# Table of Contents
- [Capabilities](#capabilities)
- [Installation](#installation)
- [Providers](/Docs)
       * [AWS](/Docs/aws.md)

## Capabilities

1.  Generate `tf` and `tfstate` files from existing infrastructure for all the
    resources.
2.  Remote state will be uploaded to S3 bucket.
3.  Connect between resources with `terraform_remote_state` (local and bucket).
4.  Save `tf` files using a custom folder tree pattern.
5.  Import by resource name and type.
6.  Support terraform 0.13 (for terraform 0.11 use v0.7.9).

Terraformer uses Terraform providers and is designed to easily support newly added resources.
To upgrade resources with new fields, all we need to do is upgrade the relevant Terraform providers.
```
Import current state to Terraform configuration from a provider

Usage:
   import [provider] [flags]
   import [provider] [command]

Available Commands:
  list        List supported resources for a provider

Flags:
  -b, --bucket string         gs://terraform-state
  -c, --connect                (default true)
  -С, --compact                (default false)
  -x, --excludes strings      firewalls,networks
  -f, --filter strings        compute_firewall=id1:id2:id4
  -h, --help                  help for google
  -O, --output string         output format hcl or json (default "hcl")
  -o, --path-output string     (default "generated")
  -p, --path-pattern string   {output}/{provider}/ (default "{output}/{provider}/{service}/")
      --projects strings
  -z, --regions strings       europe-west1, (default [global])
  -r, --resources strings     firewall,networks or * for all services
  -s, --state string          local or bucket (default "local")
  -v, --verbose               verbose mode
  -n, --retry-number          number of retries to perform if refresh fails
  -m, --retry-sleep-ms        time in ms to sleep between retries

Use " import [provider] [command] --help" for more information about a command.
```
#### Permissions

The tool requires read-only permissions to list service resources.

#### Resources

We can use `--resources` parameter to tell resources from what service you want to import.

To import resources from all services, use `--resources="*"` . If we want to exclude certain services, We can combine the parameter with `--excludes` to exclude resources from services we don't want to import e.g. `--resources="*" --excludes="iam"`.

#### Filtering

Filters are a way to choose which resources `terraformer` imports. It's possible to filter resources by its identifiers or attributes.

Use `Type` when we need to filter only one of several types of resources. Multiple filters can be combined when importing different resource types. Below an example would be importing all AWS security groups from a specific AWS VPC:
```
terraformer import aws -r sg,vpc --filter Type=sg;Name=vpc_id;Value=VPC_ID --filter Type=vpc;Name=id;Value=VPC_ID
```
We can notice how the `Name` is different for `sg` than it is for `vpc`.


##### Resource ID

Filtering is based on Terraform resource ID patterns. To find valid ID patterns for the resource, check the import part of the [Terraform documentation][terraform-providers].

[terraform-providers]: https://www.terraform.io/docs/providers/

#### Planning

The `plan` command generates a planfile that contains all the resources set to be imported. By modifying the planfile before running the `import` command, we can rename or filter the resources we'd like to import.

The rest of the subcommands and parameters are identical to the `import` command.


### Installation
We will follow the installation instruction from the release.

From Releases:

* Linux

```
export PROVIDER={aws}
curl -LO https://github.com/GoogleCloudPlatform/terraformer/releases/download/$(curl -s https://api.github.com/repos/GoogleCloudPlatform/terraformer/releases/latest | grep tag_name | cut -d '"' -f 4)/terraformer-${PROVIDER}-linux-amd64
chmod +x terraformer-${PROVIDER}-linux-amd64
sudo mv terraformer-${PROVIDER}-linux-amd64 /usr/local/bin/terraformer
```
* MacOS

```
export PROVIDER={aws}
curl -LO https://github.com/GoogleCloudPlatform/terraformer/releases/download/$(curl -s https://api.github.com/repos/GoogleCloudPlatform/terraformer/releases/latest | grep tag_name | cut -d '"' -f 4)/terraformer-${PROVIDER}-darwin-amd64
chmod +x terraformer-${PROVIDER}-darwin-amd64
sudo mv terraformer-${PROVIDER}-darwin-amd64 /usr/local/bin/terraformer
```
* Windows
1. Install Terraform - https://www.terraform.io/downloads
2. Download exe file from here - https://github.com/GoogleCloudPlatform/terraformer/releases [terraformer-aws-windows-amd64.exe]
3. Add the exe file path to path variable
4. Create a folder and initialize the terraform provider and run terraformer commands from there
   * For AWS -  refer https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started


Below is the link to download Terraform Providers:

    * AWS provider >2.25.0 - [here](https://releases.hashicorp.com/terraform-provider-aws/)
  

Information on provider plugins:
https://www.terraform.io/docs/configuration/providers.html
