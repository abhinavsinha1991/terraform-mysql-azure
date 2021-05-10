variable "myvars" {

  type = object({
    myprefix            = string
    location            = string
    mysql-user-name     = string
    mysql-root-password = string
    mysql-user-password = string
  })

  default = {
    myprefix            = "dummy"
    location            = "East US"
    mysql-user-name     = "foo"
    mysql-root-password = "mypass1234"
    mysql-user-password = "mypass123@"
  }
}