# terraform-mysql-azure

Helps you do a fully-unattended provisioning of a self-managed(VM-based) MySQL instance 
on Azure with access only from the client machine you created it from(uses 
NSG with whitelist on port 3306(mysql) & 22(SSH) from client IP only). 

### Steps to run:

1. Install terraform locally if not done already.
2. Install azure-cli locally.
3. Do an `az login` with your credentials on the local machine.
4. Override the following variables in `terraform.tfvars` to your liking:
   ```
   myvars = {
    myprefix = "playground"  #prefix for all Azure reosurce names
    location = "East US"
    mysql-user-name = "foo"
    mysql-root-password = "mypass1234"
    mysql-user-password = "mypass1234"
   }
   ```
5. Run the Terraform config using `terraform apply -auto-approve`

Features used:

1. tfvars
2. Provisioners(file and remote-exec)
3. templatefile function