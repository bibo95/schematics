###############################################################################
# IBM Confidential
# OCO Source Materials
# IBM Cloud Schematics
# (C) Copyright IBM Corp. 2022 All Rights Reserved.
# The source code for this program is not  published or otherwise divested of
# its trade secrets, irrespective of what has been deposited with
# the U.S. Copyright Office.
###############################################################################

variable "agent_name" {
  description = "Name of the agent."
  type        = string
  default     = "my-project"

  # validation {
  #   error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters. The maximum length for prefix is 27 characters"
  #   condition     = length(var.agent_prefix) <= 27
  # }
}


variable "location" {
  description = "Location of the agent services.  It must be the same as the agent infrastructure/cluster location."
  type        = string
  default     = "us-south"
}

variable "resource_group_name" {
  description = "Name of resource group used where agent infrastructure was provisioned"
  type        = string

  # validation {
  #   error_message = "Unique ID must begin and end with a letter and contain only letters, numbers, and - characters."
  #   condition     = can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.resource_group))
  # }
}


variable "schematics_endpoint_location" {
  description = "Location of the schematics endpoint. This location is used to connect your agent with schematics service. The valid locations are us|eu|us-south|us-east|eu-de|eu-gb"
  type        = string
  default     = "us-south"

  validation {
    condition     = contains(["us-south", "us-east", "eu-de", "eu-gb", "eu-fr"], var.schematics_endpoint_location)
    error_message = "Invalid input, options: \"us-south\", \"us-east\", \"eu-de\", \"eu-gb\"."
  }
}


##############################################################################
# Cluster Variables
##############################################################################

variable "cluster_id" {
  description = "ID of the cluster used to run the agent service."
  type        = string
}


##############################################################################
# LogDNA Variables
##############################################################################

variable "logdna_name" {
  description = "Name of the IBM Log Analysis service instance, used to send the agent logs."
  type        = string
  #default     = "my-project-logdna"
}

variable "ibmcloud_api_key" {
  description = "The IBM Cloud API Key used to deploy the schematics agent resources. If not provided, resources will be deployed using the logged in user credentials."
  type        = string
  sensitive   = true
  default     = ""
}

##############################################################################