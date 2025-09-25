O QUE IMPLEMENTEI NO PROJETO

Eu fui responsável por toda a infraestrutura e automação do projeto, implementando:

- Infrastructure as Code com Terraform  
- CI/CD com GitHub Actions  
- Workload Identity Federation  
- Containerização e Cloud Run  
- Monitoramento e Budget Management  
- Segurança e Permissionamento  

---

## 1. TERRAFORM (Infrastructure as Code)

### O que eu fiz:
- Criei toda infraestrutura do Google Cloud via código  
- Gerenciei o state do Terraform  


**Componentes principais que usei:**

```hcl
# Provider - Define qual cloud usar
provider "google" {
  project = "meu-projeto"
  region  = "us-central1"
}

# Resource - Recurso que será criado
resource "google_storage_bucket" "exemplo" {
  name     = "meu-bucket"
  location = "US"
}

# Variables - Parâmetros reutilizáveis
variable "project_id" {
  description = "ID do projeto"
  type        = string
}

# Outputs - Valores que serão expostos
output "bucket_name" {
  value = google_storage_bucket.exemplo.name
}
