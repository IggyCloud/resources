terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# --- Postgres ---
resource "kubernetes_service_v1" "postgres" {
  metadata {
    name = "postgres"
  }
  spec {
    selector = {
      app = "postgres"
    }
    port {
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_stateful_set_v1" "postgres" {
  metadata {
    name = "postgres"
  }
  spec {
    service_name = "postgres"
    replicas     = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "ankane/pgvector:latest"
          port {
            container_port = 5432
          }
          args = [
            "-c", "max_connections=400",
            "-c", "shared_buffers=512MB",
            "-c", "effective_cache_size=1536MB",
            "-c", "maintenance_work_mem=128MB",
            "-c", "checkpoint_completion_target=0.9",
            "-c", "wal_buffers=16MB",
            "-c", "default_statistics_target=100",
            "-c", "random_page_cost=1.1",
            "-c", "effective_io_concurrency=200",
            "-c", "work_mem=1285kB",
            "-c", "huge_pages=off",
            "-c", "min_wal_size=1GB",
            "-c", "max_wal_size=4GB",
            "-c", "shared_preload_libraries=pg_stat_statements",
            "-c", "logging_collector=on",
            "-c", "log_directory=pg_log",
            "-c", "log_filename=postgresql-%Y-%m-%d_%H%M%S.log",
            "-c", "log_rotation_age=5min",
            "-c", "log_rotation_size=50MB",
            "-c", "log_min_duration_statement=250ms",
            "-c", "log_statement=none",
            "-c", "log_checkpoints=on",
            "-c", "log_connections=off",
            "-c", "log_disconnections=off",
            "-c", "log_destination=stderr"
          ]
          resources {
            limits = {
              cpu    = "1"
              memory = "2Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }
          env {
            name  = "POSTGRES_DB"
            value = "catalogdb"
          }
          env {
            name  = "POSTGRES_HOST_AUTH_METHOD"
            value = "trust"
          }
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "postgres-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    }
  }
}

# --- RabbitMQ ---
resource "kubernetes_service_v1" "rabbitmq" {
  metadata {
    name = "eventbus"
  }
  spec {
    selector = {
      app = "rabbitmq"
    }
    port {
      port        = 5672
      target_port = 5672
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "rabbitmq" {
  metadata {
    name = "rabbitmq"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "rabbitmq"
      }
    }
    template {
      metadata {
        labels = {
          app = "rabbitmq"
        }
      }
      spec {
        container {
          name  = "rabbitmq"
          image = "rabbitmq:3-management"
          port {
            container_port = 5672
          }
          env {
            name  = "RABBITMQ_DEFAULT_USER"
            value = "user"
          }
          env {
            name  = "RABBITMQ_DEFAULT_PASS"
            value = "password"
          }
        }
      }
    }
  }
}

# --- Catalog API ---
resource "kubernetes_deployment_v1" "catalog_api" {
  metadata {
    name = "catalog-api"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "catalog-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "catalog-api"
        }
      }

      spec {
        container {
          name  = "catalog-api"
          image = "catalog-api:latest"
          image_pull_policy = "Never"

          port {
            container_port = 8080
          }

          # Azure B1 tier mimic: 1 vCPU, 1GB RAM
          resources {
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }

          env {
            name  = "ConnectionStrings__catalogdb"
            value = "Host=postgres;Port=5432;Database=catalogdb;Username=postgres;Password=password;Maximum Pool Size=300"
          }

          env {
            name  = "ConnectionStrings__eventbus"
            value = "amqp://user:password@eventbus:5672"
          }

          env {
            name  = "DisableAuth"
            value = "true"
          }

          env {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = "Development"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "catalog_api" {
  metadata {
    name = "catalog-api"
  }

  spec {
    selector = {
      app = "catalog-api"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}
