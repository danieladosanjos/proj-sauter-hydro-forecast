variable "project_id" {
  description = "ID do projeto Google Cloud"
  type        = string
  default     = "affable-elf-472819-k2"
}

variable "region" {
  description = "Região padrão"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona padrão"
  type        = string
  default     = "us-central1-a"
}

variable "mentor_emails" {
  description = "Emails dos mentores para alertas"
  type        = list(string)
  default     = [
    "mentor1@exemplo.com",
    "mentor2@exemplo.com", 
    "mentor3@exemplo.com"
  ]
}