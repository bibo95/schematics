###############################################################################
# IBM Confidential
# OCO Source Materials
# IBM Cloud Schematics
# (C) Copyright IBM Corp. 2022 All Rights Reserved.
# The source code for this program is not  published or otherwise divested of
# its trade secrets, irrespective of what has been deposited with
# the U.S. Copyright Office.
###############################################################################


##############################################################################
# logdna data
##############################################################################

data "ibm_resource_instance" "logdna" {
  name              = var.logdna_name
  resource_group_id = data.ibm_resource_group.resource_group_logdna.id
}

resource "ibm_resource_key" "logdna_key" {
  name                 = "${var.logdna_name}-key"
  role                 = "Manager"
  resource_instance_id = data.ibm_resource_instance.logdna.id
}

##############################################################################


##############################################################################
# Create logdna agent resources
##############################################################################

resource "kubernetes_config_map" "logdna_agent" {
  metadata {
    name      = "schematics-logdna-agent-config"
    namespace = "schematics-ibm-observe"
  }

  data = {
    logdna-agent-key = ibm_resource_key.logdna_key.credentials["ingestion_key"]
    logdna-host      = "logs.private.${var.location}.logging.cloud.ibm.com"
  }

  depends_on = [kubernetes_namespace.namespace]
}

resource "kubernetes_service_account" "logdna_agent" {
  metadata {
    name      = "logdna-agent"
    namespace = "schematics-ibm-observe"
  }

  depends_on = [kubernetes_config_map.logdna_agent, kubernetes_namespace.namespace]
}

resource "kubernetes_cluster_role" "logdna_agent" {
  metadata {
    name = "logdna-agent"
  }

  rule {
    verbs      = ["get", "list", "create", "watch"]
    api_groups = [""]
    resources  = ["events"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["pods"]
  }

  depends_on = [kubernetes_service_account.logdna_agent]
}

resource "kubernetes_role" "logdna_agent" {
  metadata {
    name      = "logdna-agent"
    namespace = "schematics-ibm-observe"
  }

  rule {
    verbs      = ["get", "list", "create", "watch"]
    api_groups = [""]
    resources  = ["configmaps"]
  }

  depends_on = [kubernetes_cluster_role.logdna_agent, kubernetes_namespace.namespace]
}

resource "kubernetes_role_binding" "logdna_agent" {
  metadata {
    name      = "logdna-agent"
    namespace = "schematics-ibm-observe"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "logdna-agent"
    namespace = "schematics-ibm-observe"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "logdna-agent"
  }

  depends_on = [kubernetes_role.logdna_agent, kubernetes_namespace.namespace]
}

resource "kubernetes_cluster_role_binding" "logdna_agent" {
  metadata {
    name = "logdna-agent"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "logdna-agent"
    namespace = "schematics-ibm-observe"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "logdna-agent"
  }

  depends_on = [kubernetes_role_binding.logdna_agent]
}

resource "kubernetes_daemonset" "logdna_agent" {
  metadata {
    name      = "logdna-agent"
    namespace = "schematics-ibm-observe"
  }

  spec {
    selector {
      match_labels = {
        app = "logdna-agent"
      }
    }

    template {
      metadata {
        labels = {
          app = "logdna-agent"
        }
      }

      spec {
        volume {
          name = "varlog"

          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "vardata"

          host_path {
            path = "/var/data"
          }
        }

        volume {
          name = "varlibdockercontainers"

          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        volume {
          name = "mnt"

          host_path {
            path = "/mnt"
          }
        }

        volume {
          name = "osrelease"

          host_path {
            path = "/etc/os-release"
          }
        }

        volume {
          name = "logdnahostname"

          host_path {
            path = "/etc/hostname"
          }
        }

        container {
          name  = "logdna-agent"
          image = "icr.io/ext/logdna-agent:2.1.9"

          env {
            name = "LOGDNA_AGENT_KEY"

            value_from {
              config_map_key_ref {
                name = "schematics-logdna-agent-config"
                key  = "logdna-agent-key"
              }
            }
          }

          env {
            name = "LOGDNA_HOST"

            value_from {
              config_map_key_ref {
                name = "schematics-logdna-agent-config"
                key  = "logdna-host"
              }
            }
          }

          env {
            name  = "RUST_LOG"
            value = "info"
          }

          env {
            name = "NODE_NAME"

            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name = "NAMESPACE"

            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name  = "LOGDNA_EXCLUDE"
            value = "/var/log/at/**"
          }

          env {
            name  = "LOGDNA_TAGS"
            value = "region:${var.location},env:production,schematics,logging"
          }

          resources {
            limits = {
              memory = "500Mi"
            }

            requests = {
              cpu = "20m"
            }
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
          }

          volume_mount {
            name       = "vardata"
            mount_path = "/var/data"
          }

          volume_mount {
            name       = "varlibdockercontainers"
            read_only  = true
            mount_path = "/var/lib/docker/containers"
          }

          volume_mount {
            name       = "mnt"
            read_only  = true
            mount_path = "/mnt"
          }

          volume_mount {
            name       = "osrelease"
            mount_path = "/etc/os-release"
          }

          volume_mount {
            name       = "logdnahostname"
            mount_path = "/etc/logdna-hostname"
          }

          image_pull_policy = "Always"
        }

        service_account_name = "logdna-agent"
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "100%"
      }
    }
  }

  depends_on = [kubernetes_cluster_role_binding.logdna_agent, kubernetes_namespace.namespace]
}


##############################################################################
