terraform workspace select example1
terraform destroy -auto-approve
terraform workspace select example2
terraform destroy -auto-approve
terraform workspace select default
terraform destroy -auto-approve