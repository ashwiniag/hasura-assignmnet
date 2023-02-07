# -------------------outputs----------------

# -------------------variables--------------
locals {
  backeend_name = "env-echo"
  namespace = "backend-applications"

}

variable "backend_app" {
  type = map(string)
  default = {
    port                = "8080"
    count               = "1"
//    request_cpu       = "100m"
//    request_ram       = "300Mi"
//    limit_cpu         = "200m"
//    limit_ram         = "400Mi"
  }
}

resource "kubernetes_secret" "hasura_secrets" {
  metadata {
    name = local.namespace
  }

  data = {
    "HASURA_ONE_KEY_VALUE" = base64encode("DUMMYVALUE.tf=")
  }

}


# -------------------resources--------------

resource "kubernetes_namespace" "backend_app" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_deployment" "backend_app" {

  metadata {
    name      = "${local.backeend_name}-deployment"
    namespace = local.namespace
    labels = {
      app = local.backeend_name
    }
  }

  spec {
    replicas = var.backend_app.count

    selector {
      match_labels = {
        app = local.backeend_name

      }
    }

    template {
      metadata {
        labels = {
          app = local.backeend_name

        }
      }

      spec {
        restart_policy = "Always"

        node_selector = {
          group = "common_node"
        }

        container {
          image             = "024662722948.dkr.ecr.ap-south-1.amazonaws.com/hasura-application" //*
          name              = local.backeend_name
          image_pull_policy = "Always"
          // For testing scope disabling this.
//          resources {
//            requests = {
//              cpu               = var.backend_app.request_cpu
//              memory            = var.backend_app.request_ram
//            }
//
//            limits = {
//              cpu               = var.backend_app.limit_cpu
//              memory            = var.backend_app.limit_ram
//            }
//          }

          env {
            name  = "HASURA_MY_ENV"
            value = kubernetes_secret.hasura_secrets.data.HASURA_ONE_KEY_VALUE
          }

          env {
            name  = "HASURA_MY_ENV_NEW"
            value = kubernetes_secret.hasura_secrets.data.HASURA_ONE_KEY_VALUE
          }

          port {
            name           = "endpoint"
            container_port = var.backend_app.port
            protocol       = "TCP"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend_app_service" {
  metadata {
    name      = "${local.backeend_name}-svc"
    namespace = local.namespace
    labels = {
      app = local.backeend_name

    }
  }

  spec {
    selector = {
      app = local.backeend_name

    }

    port {
      name        = "endpoint"
      port        = 80
      target_port = var.backend_app.port
    }
  }
}

