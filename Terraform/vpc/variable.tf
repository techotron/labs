variable "private_subnet" {
  type      = "list"
  default   = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet" {
  type      = "list"
  default   = ["10.0.255.0/24", "10.0.254.0/24"]
}

variable "ssh_security_group" {
  type      = "list"
  default   = ["22"]
}

variable "web_security_group" {
  type      = "list"
  default   = ["80", "443"]
}

variable "app" {
  type      = "string"
  default   = "terraform"
}
