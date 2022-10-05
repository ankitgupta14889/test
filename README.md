# Terraformer

It's a CLI tool that generates `tf` and `tfstate` files based on the existing infrastructure.


# Table of Contents
- [Capabilities](#capabilities)
- [Installation](#installation)
- [Provider](#provider)
       * [AWS](/Docs/aws.md)
- [Implementation](#implementation)

## Capabilities

1. Generate `tf` and `tfstate` files from existing infrastructure for all the
    resources.
2. Remote state will be uploaded to S3 bucket.
3. Save `tf` files using a custom folder tree pattern.
4. Import by resource name and type.
5. Support terraform 0.13 (for terraform 0.11 use v0.7.9).

Terraformer uses Terraform providers and is designed to easily support newly added resources.
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
2. Download exe file from here - https://github.com/GoogleCloudPlatform/terraformer/releases/download/0.8.22/terraformer-aws-windows-amd64.exe
3. Add the exe file path to path variable
4. Create a folder and initialize the terraform provider and run terraformer commands from there
   * For AWS -  refer https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started

### Provider

Below is the link to download Terraform Providers:

    * AWS provider >2.25.0 - [here](https://releases.hashicorp.com/terraform-provider-aws/)
  

Information on provider plugins:
https://www.terraform.io/docs/configuration/providers.html

### implementation

##### Initialization

Terraform initialization stage for installing the provider plugin.

To pre-install a plugin, Create a provider.tf file.

```
terraform {
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.25"
    }
  }
}

provider "aws" {
 profile = "default"
}
```

Initialize the Terraform configuration via the init command.

```
~$ terraform init
Initializing the backend...
~~~
Terraform has been successfully initialized!
```

##### Importing

Now we will import the resources.

```
~$ terraformer import aws --path-pattern="{output}/" --compact=true --regions=ap-southeast-2 --resources=ecs,rds
aws importing region ap-southeast-2
aws importing... ecs
~~~
aws importing... rds
~~~
aws Connecting....
aws save
aws save tfstate
```

In the above example, We use the following keys.

1. aws - The provider name.
2. --path-pattern - The path to the configuration files generated by the utility.
3. --compact=true - Writing configuration for all types of resources into one file.
4. --regions - The provider's region.
5. --resources - Types of resources to import.


Now we can do some planning with the imported configuration.

```
~/Koalaimport$ terraform plan
Refreshing Terraform state in-memory prior to plan...
0 to add, 0 to change, 0 to destroy
```

##### Applying the configuration

Its time to apply the configuration.

```
~/Koalaimport$ terraform apply
                ~~~
Terraform will perform the following actions:

Plan: 0 to add, 0 to change, 0 to destroy.
                ~~~
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

