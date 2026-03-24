#### `module`
Terraform `module` blocks allow us to load in external Terraform configurations. In this chapter, we've changed the webserver cluster and database components we made into modules. This allows us to create seperate staging and production environments, without duplicating code. The staging and production environments are referred to as 'root modules', and the "templates" so to speak are referred to as 'reusable modules'. Reusable modules can take input variables and have output values, just like root modules. In the root module, you can configure the input variables, and make use of the output values, of the reusable modules. This allows you to, for example, deploy fewer and smaller webserver instances in the staging environment than you do in the production environment. 


##### Remote module sources and versioning
Terraform supports retrieving modules from remote sources. In this case, we use GitHub repositories Conventionally, our modules should live in a seperate repository from our environments, but I didn't feel like doing that. So, this 'remote' source is actually this same repository. Terraform performs a git clone operation to retrieve this remote source, so we use `depth=1` url parameter to prevent unnecessary commit history cloning. We use tags in our repository to mark module versions, and select these versions using the `ref` url parameter. This way, we can test changes to the modules in our staging environment by selecting a different version, without affecting our production environment. This is generally useful when deploying to shared environments, but when doing small tests locally, it's better to use local paths, or you'll have to commit, publish, and version every small change. To add tags to our publication, we use these commands: 

```bash
$ git tag -a "v0.0.1" -m "First release of webserver-cluster module"
$ git push --follow-tags
```
