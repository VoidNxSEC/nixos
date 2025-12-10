terraform {
  required_version = ">= 1.6.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "random" {}

resource "random_password" "test_password" {
  length  = 16
  special = true
}

output "password" {
  value = random_password.test_password.result
}

