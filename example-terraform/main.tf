terraform {
  required_version = ">= 1.9.0"

  required_providers {
    example = {
      source  = "example.com/example/hello"
      version = "~> 1.0.0"
    }
  }
}

data "example_hello" "message" {
}

output "message" {
  value = data.example_hello.message.message
}
