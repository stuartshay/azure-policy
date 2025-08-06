variable "resource_group_id" {
  description = "The ID of the resource group for policy assignments"
  type        = string
}

variable "enable_policy_assignments" {
  description = "Whether to enable policy assignments"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
  default     = {}
}
