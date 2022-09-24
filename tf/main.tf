terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.17.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = "mitokentest"
  location = "southcentralus"
}

resource "azurerm_user_assigned_identity" "this" {
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name = "mitokentest"
}

data "azuread_client_config" "current" {}

resource "azuread_application" "this" {
  display_name     = "myadapp"
  identifier_uris  = ["api://mitokentest"]
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  api {
    mapped_claims_enabled          = true
    requested_access_token_version = 1

    oauth2_permission_scope {
      admin_consent_description  = "Do everything"
      admin_consent_display_name = "Everything"
      enabled                    = true
      id                         = "f55b4013-40e7-47fc-a980-4751c633dc04"
      type                       = "User"
      user_consent_description   = "User"
      user_consent_display_name  = "Everything"
      value                      = "Everything"
    }
  }

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Have this permission to get a token - setup by Joshua"
    display_name         = "JoshuasAppRole"
    enabled              = true
    id                   = "1c7c414c-04fb-4109-a2e1-53a4e4f81be0"
    value                = "Joshua.Something"
  }

  feature_tags {
    enterprise = true
    gallery    = true
  }
}

# now add service principal
resource "azuread_service_principal" "this" {
  application_id               = azuread_application.this.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  feature_tags {
    enterprise = true
    gallery    = true
  }
}

resource "azuread_app_role_assignment" "this" {
  app_role_id         = azuread_service_principal.this.app_role_ids["Joshua.Something"]
  principal_object_id = azurerm_user_assigned_identity.this.principal_id
  resource_object_id  = azuread_service_principal.this.object_id
}

/*
resource "azurerm_virtual_network" "this" {
  name                = "this-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "this" {
  name                = "this-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "machine"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = "Standard_B2ms"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "UserAssigned"
    identity_ids = ["/subscriptions/871d8e11-eea0-4735-b008-0b3194cb4416/resourcegroups/mitokentest/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mitokentest"]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}
*/
