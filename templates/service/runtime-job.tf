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
# Job 12 blocks
##############################################################################

resource "kubernetes_config_map" "runtime_job_configmap" {
  metadata {
    name      = "schematics-runtime-job-config"
    namespace = "schematics-runtime"
  }

  data = {
    JOB_HTTPADDR                   = ""
    JOB_HTTPPORT                   = 3002
    JOB_KEEPWORKFILES              = true
    JOB_SINGLEACTIONMODE           = true
    JOB_LOGGERLEVEL                = "-1"
    JOB_ATLOGGERLEVEL              = "-1"
    JOB_EXTLOGGERLEVEL             = "-1"
    JOB_EXTLOGPATH                 = "/var/log/schematics/%s.log"
    JOB_IMAGEEXTN                  = ".tif,.tiff,.gif,.png,.bmp,.jpg,.jpeg,.so"
    JOB_WHITELISTEXTN              = ".tf,.tfvars,.md,.yaml,.sh,.txt,.yml,.html,.gitignore,.tf.json,license,.js,.pub,.service,_rsa,.py,.json,.tpl,.cfg,.ps1,.j2,.zip,.conf,.crt,.key,.der,.jacl,.properties,.cer,.pem,.tmpl,.netrc"
    JOB_ANSIBLEACTIONWHITELISTEXTN = ".tf,.tfvars,.md,.yaml,.sh,.txt,.yml,.html,.gitignore,.tf.json,license,.js,.pub,.service,_rsa,.py,.json,.tpl,.cfg,.ps1,.j2,.zip,.conf,.crt,.key,.der,.cer,.pem,.bash,.tmpl"
    JOB_BLACKLISTEXTN              = ".php5,.pht,.phtml,.shtml,.asa,.asax,.swf,.xap,.tfstate,.tfstate.backup,.exe"
    JOB_ENVIRONMENT                = local.schematics_environment
    TF_VAR_SCHEMATICSLOCATION      = var.location
    TF_CLI_CONFIG_FILE             = "/home/nobody/terraform-custom.config"
    MAX_TIMEOUT                    = 3600
    JOB_ENABLETLS                  = false
    JOB_ENABLEMTLS                 = false
    # JOB_OPPONENTSCA                = var.JOB_OPPONENTSCA
    # JOB_CERTPEM                    = var.JOB_CERTPEM
    # JOB_KEYPEM                     = var.JOB_KEYPEM
  }

  depends_on = [kubernetes_namespace.namespace]

}


//creating image pull secret for job
resource "kubernetes_secret" "schematics-job-secret" {
  metadata {
    name      = "schematics-runtime-job-image-secret"
    namespace = "schematics-runtime"
  }
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "icr.io" = {
          auth = base64encode("iamapikey:${var.ibmcloud_api_key}")
        }
      }
    })
  }
  type = "kubernetes.io/dockerconfigjson"
  depends_on = [kubernetes_namespace.namespace]
}


resource "kubernetes_service" "job_service" {
  metadata {
    name      = "job-service-12-clusterip"
    namespace = "schematics-runtime"
  }

  spec {
    port {
      name        = "grpc-job"
      port        = 3002
      target_port = "grpc-job"
    }

    selector = {
      app = "runtime-job"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_namespace.namespace]
}



resource "kubernetes_deployment" "runtime_job" {
  timeouts {
    create = "60m"
    delete = "60m"
  }
  metadata {
    name      = "runtime-job"
    namespace = "schematics-runtime"


    labels = {
      app = "runtime-job"
      appcode = "AP24664"
      codeap = "AP24664"
      opscontact = "mohamed_eloirrak_at_bnpparibas.com"
      tier = "PA"
    }

    annotations = {
      "kubernetes.io/change-cause" = "schematics-job_1338"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "runtime-job"
        appcode = "AP24664"
        codeap = "AP24664"
        opscontact = "mohamed_eloirrak_at_bnpparibas.com"
        tier = "PA"
      }
    }

    template {
      metadata {
        labels = {
          app = "runtime-job"
          build = "job-1338"
          appcode = "AP24664"
          codeap = "AP24664"
          opscontact = "mohamed_eloirrak_at_bnpparibas.com"
          tier = "PA"
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
        }

        init_container {
          name    = "fix-permissions-extlog"
          image   = "private.fr2.icr.io/schematics-remote/ubi-minimal:8.6"
          command = ["sh", "-c", "chmod -R a+rwx /var/log/schematics"]

          volume_mount {
            name       = "ext-logs"
            mount_path = "/var/log/schematics"
          }
        }

        image_pull_secrets {
          name = "schematics-runtime-job-image-secret"
        }

        container {
          name  = "runtime-job"
          image = local.schematics_runtime_job_image

          port {
            name           = "grpc-job"
            container_port = 3002
          }

          env_from {
            config_map_ref {
              name = "schematics-runtime-job-config"
            }
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }

            requests = {
              cpu    = "500m"
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

          security_context {
            run_as_user     = 1001
            run_as_group    = 1001
            run_as_non_root = true
          }
        }

        restart_policy                   = "Always"
        termination_grace_period_seconds = 180000
      }
    }

    revision_history_limit = 5
  }

  depends_on = [kubernetes_service.job_service, kubernetes_config_map.runtime_job_configmap, kubernetes_namespace.namespace, kubernetes_secret.schematics-job-secret]
}

##############################################################################
