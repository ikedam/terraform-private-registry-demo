terraform {
  required_version = ">= 1.9.0"

  required_providers {
    hello = {
      source  = "example.com/example/hello"
      version = "~> 1.0.0"
    }
  }
}

data "hello_world" "message" {
}

output "message" {
  value = data.hello_world.message.message
}
