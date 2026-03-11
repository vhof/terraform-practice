In this chapter we use Terraform to deploy a simple website that utilizes AWS's features for automatic health checks, load balancing and webserver instance launching. In short it works as follows: 

* Load balancer consists of [Listeners, Listener rules, Target groups]
* Listener receives HTTP request on public facing IP
* Listener rule matches request pattern and forwards request to correct Target group
* Target group contains an Auto Scaling Group (ASG)
  * Target group handles health checks, ASG handles launching/scaling instances
  * ASG contains webserver instances that produce HTTP response
    * Instances are simple Ubuntu Server images
* HTTP response returns to Listener, who forwards to requester

All of the above lives inside a VPC (Virtual Private Cloud), essentially a VPN. Only the Load balancer has a public IP. 

The following Terraform constructs are used: 
* `provider`
* `data`
* `variable`
* `resource`
* `output`

#### `provider`
`provider` informs Terraform which API calls to use and what kind of resources are available. In this case our provider is Amazon Web Services (AWS).

To make these API calls, Terraform needs an access key of a user that has the appropriate privileges. For the purpose of these exercises, I've created a user with Administrator privileges and stored its credentials in my Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` 

#### `data`
`data` sources are external read-only objects. We need these information sources for our infrastructure configurations, but cannot know them beforehand. The arguments you pass in are typically search filters that indicate to the data source what information you’re looking for. 

#### `variable`
`variable`s are input variables for your configuration. It can have type and other validation constraints, and a default value. A variable can also be marked as sensitive, which will hide it from the command line preview and planning outputs. Terraform will look for a value in the following order:
1. Any -var and -var-file options on the command line in the order provided and
variables from HCP Terraform
2. Any *.auto.tfvars or *.auto.tfvars.json files in lexical order
3. The terraform.tfvars.json file
4. The terraform.tfvars file
5. Environment variables
6. The default argument of the variable block

Apart from special cases such as AWS keys, the syntax for general Terraform Environment variables is `TF_VAR_<variable name>`

#### `resource`
`resources` are the actual components of an infrastructure, e.g. routing tables, load balancers, webservers, databases. These are the bread and butter of what we're actually trying to accomplish with Terraform.

#### `output`
`output`s are Terraform output values. They are displayed on the command line (after (re-)deploying) or can be accessed by other Terraform configurations using this module. 
