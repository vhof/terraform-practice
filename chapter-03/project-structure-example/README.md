In this chapter we add a small database to our project. We isolate these infrastructure components from each other, because (among other reasons) a database infrastructure will be updated less frequently. A consequence of this isolation is that we cannot directly/locally reference resources from other components. In the case of a database, we probably want to know and use its IP and port inside of our website configuration. To this end, we now store the state files of our Terraform configurations remotely. Terraform saves output variables in the state file. In this case, we store our state file in an AWS S3 bucket, which is essentially AWS cloud storage. The setup for this remote storage was also done through a Terraform configuration, found in [/global/s3](/terraform-practice/chapter-03/project-structure-example/global/s3/). Another major advantage of remote state files, is that it allows for collaborations. Collaboration platforms such as GitHub don't have file locking, which is essential for a Terraform state files. In the book, they make us of a special DynamoDB to store a lock file. However S3 buckets now support file locking out-of-the-box, so I use that instead. 

In addition to adding a database, the components themselves are now also more structured and readable by seperating the following across different files:

* External dependencies, i.e. data sources (`dependencies.tf`)
* Input variables (`variables.tf`)
* Output values (`outputs.tf`)

The remainder of the configurations, namely the providers, backend configurations, and all of the resources, remain in `main.tf`

The following new Terraform concepts are used: 
* `terraform`
* `templatefile()`

#### `terraform`
The top-level `terraform` block allows us to configure Terraform behavior, such as version and backend. 

#### `templatefile()`
To improve code clarity, we moved the launch script of our webserver instances to a seperate file, [user-data.sh](/terraform-practice/chapter-03/project-structure-example/stage/services/webserver-cluster/user-data.sh). Using the the `templatefile()` function, we can still use Terraform string interpolation. The function takes a path string and the values for interpolation as an object (an object is similar to JavaScript / JSON objects, being a simple flexible set of key-value pairs). 