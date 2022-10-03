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
# sandbox blocks
##############################################################################

//creating configmap
resource "kubernetes_config_map" "sandbox" {
  metadata {
    name      = "sandbox"
    namespace = "schematics-sandbox"
  }

  data = {
    CATALOGURL                         = "https://cm.globalcatalog.test.cloud.ibm.com/api/v1-beta"
    IAMENDPOINT                        = "https://iam.test.cloud.ibm.com"
    SANDBOX_ANSIBLEACTIONWHITELISTEXTN = ".tf,.tfvars,.md,.yaml,.sh,.txt,.yml,.html,.gitignore,.tf.json,license,.js,.pub,.service,_rsa,.py,.json,.tpl,.cfg,.ps1,.j2,.zip,.conf,.crt,.key,.der,.cer,.pem,.bash,.tmpl"
    SANDBOX_ATLOGGERLEVEL              = "-1"
    SANDBOX_BLACKLISTEXTN              = ".php5,.pht,.phtml,.shtml,.asa,.asax,.swf,.xap,.tfstate,.tfstate.backup,.exe"
    SANDBOX_ENABLEENV                  = "true"
    SANDBOX_ENABLEMTLS                 = "false"
    SANDBOX_ENABLETLS                  = "false"
    SANDBOX_EXTLOGGERLEVEL             = "-1"
    SANDBOX_EXTLOGPATH                 = "/var/log/schematics/%s.log"
    SANDBOX_HTTPADDR                   = "none"
    SANDBOX_HTTPPORT                   = "3000"
    SANDBOX_IMAGEEXTN                  = ".tif,.tiff,.gif,.png,.bmp,.jpg,.jpeg,.so"
    SANDBOX_LOGGERLEVEL                = "-1"
    SANDBOX_SHUTDOWNREPORTINTERVAL     = "600"
    SANDBOX_WHITELISTEXTN              = ".tf,.tfvars,.md,.yaml,.sh,.txt,.yml,.html,.gitignore,.tf.json,license,.js,.pub,.service,_rsa,.py,.json,.tpl,.cfg,.ps1,.j2,.zip,.conf,.crt,.key,.der,.jacl,.properties,.cer,.pem,.tmpl,.netrc"
  }
  depends_on = [kubernetes_namespace.namespace]
}


//creating image pull secret for sandbox
resource "kubernetes_secret" "schematics-sandbox-secret" {
  metadata {
    name      = "schematics-sandbox-image-secret"
    namespace = "schematics-sandbox"
  }
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "private.fr2.icr.io" = {
          auth = base64encode("iamapikey:${var.ibmcloud_api_key}")
        }
      }
    })
  }
  type = "kubernetes.io/dockerconfigjson"
  depends_on = [kubernetes_namespace.namespace]
}

//creating service
resource "kubernetes_service" "sandbox_service" {
  metadata {
    name      = "sandbox-service"
    namespace = "schematics-sandbox"
  }

  spec {
    port {
      name        = "grpc-sandbox"
      protocol    = "TCP"
      port        = 3000
      target_port = "grpc-sandbox"
    }

    selector = {
      app = "sandbox"
    }

    type             = "ClusterIP"
    session_affinity = "None"
  }
  depends_on = [kubernetes_namespace.namespace]
}

//creating deployment
resource "kubernetes_deployment" "sandbox" {
  metadata {
    name      = "sandbox"
    namespace = "schematics-sandbox"

    labels = {
      app = "sandbox"
    }
  }
  timeouts {
    create = "60m"
    delete = "60m"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "sandbox"
      }
    }

    template {
      metadata {
        labels = {
          app = "sandbox"

          build = "sandbox-1"
        }
      }

      spec {
        volume {
          name = "at-events"

          host_path {
            path = "/var/log/at"
          }
        }

        volume {
          name = "ext-logs"

          host_path {
            path = "/var/log/schematics"
          }
        }

        init_container {
          name    = "fix-permissions"
          image   = "private.fr2.icr.io/schematics-remote/ubi-minimal:8.6"
          command = ["sh", "-c", "chmod -R a+rwx /var/log/at"]

          volume_mount {
            name       = "at-events"
            mount_path = "/var/log/at"
          }

          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "IfNotPresent"

          security_context {
            run_as_user = 0
          }
        }

        init_container {
          name    = "fix-permissions-extlog"
          image   = "private.fr2.icr.io/schematics-remote/ubi-minimal:8.6"
          command = ["sh", "-c", "chmod -R a+rwx /var/log/schematics"]

          volume_mount {
            name       = "ext-logs"
            mount_path = "/var/log/schematics"
          }

          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "IfNotPresent"

          security_context {
            run_as_user = 0
          }
        }

        container {
          name  = "sandbox"
          image = local.schematics_sandbox_image

          port {
            name           = "grpc-sandbox"
            container_port = 3000
            protocol       = "TCP"
          }

          env_from {
            config_map_ref {
              name = "sandbox"
            }
          }

          resources {
            limits = {
              cpu = "500m"

              memory = "1Gi"
            }

            requests = {
              cpu = "500m"

              memory = "1Gi"
            }
          }

          volume_mount {
            name       = "at-events"
            mount_path = "/var/log/at"
          }

          volume_mount {
            name       = "ext-logs"
            mount_path = "/var/log/schematics"
          }

          lifecycle {
            pre_stop {
              exec {
                command = ["/home/nobody/scripts/pre-stop.sh"]
              }
            }
          }

          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          image_pull_policy          = "IfNotPresent"

          security_context {
            run_as_user     = 1001
            run_as_group    = 1001
            run_as_non_root = true
          }
        }

        restart_policy                   = "Always"
        termination_grace_period_seconds = 180000
        dns_policy                       = "ClusterFirst"

        image_pull_secrets {
          name = "schematics-sandbox-image-secret"
        }
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "25%"
        max_surge       = "25%"
      }
    }

    revision_history_limit    = 5
    progress_deadline_seconds = 600
  }
  depends_on = [kubernetes_namespace.namespace, kubernetes_secret.schematics-sandbox-secret]
}
