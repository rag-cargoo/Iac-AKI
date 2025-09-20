terraform {
  backend "local" {
    path = "../../state/production/terraform.tfstate"
  }
}
