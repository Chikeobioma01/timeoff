variable "namespace" {
  type        = string
  default     = ""
  description = "The namespace to install the release into. Defaults to default."
}

variable "chart_version" {
  type        = string
  default     = ""
  description = "Specify the exact chart version to install. If this is not specified, the latest version is installed. helm_release will not automatically grab the latest release, version must explicitly upgraded when upgrading an installed chart."
}

variable "set" {
  type        = list(any)
  default     = []
  description = "Value block with custom values to be merged with the values yaml."
}

variable "set_sensitive" {
  type        = list(any)
  default     = []
  description = "Value block with custom sensitive values to be merged with the values yaml that won't be exposed in the plan's diff."
}
variable "set_list" {
  type        = list(any)
  default     = []
  description = "Value block with list of custom values to be merged with the values yaml."
}

variable "enabled" {
  type        = string
  default     = true
  description = "Enable or disable the resources"
}

variable "name" {
  type        = string
  default     = ""
  description = "Release name. The length must not be longer than 53 characters."
}

variable "chart" {
  type        = string
  default     = ""
  description = "Chart name to be installed. The chart name can be local path, a URL to a chart, or the name of the chart if repository is specified. It is also possible to use the <repository>/<chart> format here if you are running Terraform on a system that the repository has been added to with helm repo add but this is not recommended."
}

variable "repository" {
  type        = string
  default     = ""
  description = "Repository URL where to locate the requested chart."
}

variable "create_namespace" {
  type        = bool
  default     = false
  description = "Create the namespace if it does not yet exist. Defaults to false."
}

variable "cleanup_on_fail" {
  type        = bool
  default     = false
  description = "Allow deletion of new resources created in this upgrade when upgrade fails. Defaults to false"
}

variable "repository_config" {
  type        = map(any)
  default     = {}
  description = "repository configuration"
}

variable "devel" {
  type        = string
  default     = null
  description = "Use chart development versions, too. Equivalent to version '>0.0.0-0'. If version is set, this is ignored."
}

variable "verify" {
  type        = bool
  default     = false
  description = "Verify the package before installing it. Helm uses a provenance file to verify the integrity of the chart; this must be hosted alongside the chart. For more information see the Helm Documentation. Defaults to false."
}

variable "keyring" {
  type        = string
  default     = null
  description = "Location of public keys used for verification. Used only if verify is true. Defaults to /.gnupg/pubring.gpg in the location set by home"
}

variable "timeout" {
  type        = number
  default     = 300
  description = "Time in seconds to wait for any individual kubernetes operation (like Jobs for hooks). Defaults to 300 seconds."
}

variable "disable_webhooks" {
  type        = bool
  default     = false
  description = "Prevent hooks from running. Defaults to false."
}

variable "reuse_values" {
  type        = bool
  default     = false
  description = "When upgrading, reuse the last release's values and merge in any overrides. If 'reset_values' is specified, this is ignored. Defaults to false."
}

variable "reset_values" {
  type        = bool
  default     = false
  description = " When upgrading, reset the values to the ones built into the chart. Defaults to false."
}

variable "force_update" {
  type        = bool
  default     = false
  description = "Force resource update through delete/recreate if needed. Defaults to false."
}

variable "recreate_pods" {
  type        = bool
  default     = false
  description = " Perform pods restart during upgrade/rollback. Defaults to false."
}

variable "max_history" {
  type        = number
  default     = 0
  description = "Maximum number of release versions stored per release. Defaults to 0 (no limit)."
}

variable "atomic" {
  type        = bool
  default     = false
  description = "If set, installation process purges chart on fail. The wait flag will be set automatically if atomic is used. Defaults to false."
}

variable "skip_crds" {
  type        = bool
  default     = false
  description = "If set, no CRDs will be installed. By default, CRDs are installed if not already present. Defaults to false."
}

variable "render_subchart_notes" {
  type        = bool
  default     = true
  description = "If set, render subchart notes along with the parent. Defaults to true."
}

variable "disable_openapi_validation" {
  type        = bool
  default     = false
  description = " If set, the installation process will not validate rendered templates against the Kubernetes OpenAPI Schema. Defaults to false."
}

variable "wait" {
  type        = bool
  default     = true
  description = "Will wait until all resources are in a ready state before marking the release as successful. It will wait for as long as timeout. Defaults to true."
}

variable "wait_for_jobs" {
  type        = bool
  default     = false
  description = "f wait is enabled, will wait until all Jobs have been completed before marking the release as successful. It will wait for as long as timeout. Defaults to false."
}

variable "values" {
  type        = list(string)
  default     = []
  description = " List of values in raw yaml to pass to helm. Values will be merged, in order, as Helm does with multiple -f options."
}

variable "dependency_update" {
  type        = bool
  default     = false
  description = "Runs helm dependency update before installing the chart. Defaults to false."
}

variable "replace" {
  type        = bool
  default     = false
  description = "Re-use the given name, only if that name is a deleted release which remains in the history. This is unsafe in production. Defaults to false."
}

variable "description" {
  type        = string
  default     = null
  description = "Set release description attribute (visible in the history)."
}

variable "postrender" {
  type        = list(any)
  default     = []
  description = "Configure a command to run after helm renders the manifest which can alter the manifest contents."
}

variable "pass_credentials" {
  type        = bool
  default     = false
  description = "Pass credentials to all domains. Defaults to false."
}

variable "lint" {
  type        = bool
  default     = false
  description = "Run the helm chart linter during the plan. Defaults to false."
}