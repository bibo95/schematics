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
# Jobrunner blocks
##############################################################################

resource "kubernetes_config_map" "jobrunner_configmap" {
  metadata {
    name      = "schematics-jobrunner-config"
    namespace = "schematics-job-runtime"
  }

  data = {
    JR_PROFILEID          = ibm_iam_trusted_profile.iam_trusted_profile.id
    JR_AGENTNAME          = var.agent_name
    JR_AGENTLOCATION     = var.location
    JR_ALLOWMULTIPLEAGENTS = "true"
    JR_SCHEMATICSENDPOINT = local.schematics_endpoint
    JR_EXTLOGPATH         = "/var/log/schematics/%s.log"
    JR_SAVESERVICECOPY    = true
    JR_ATLOGPATH          = "/var/log/at/%s.log"
    JR_HTTPADDR           = ""
    JR_HTTPPORT           = 2021
    JR_REGION             = var.location
    JR_IAMURL             = local.iam_url
    JR_JOB12SERVICENAME   = "job-service-12-clusterip.schematics-runtime"
    JR_JOB12SERVICEPORT   = 3002
    JR_SBOXSERVICENAME    = "sandbox-service.schematics-sandbox"
    JR_SBOXSERVICEPORT    = 3000
    JR_COMPATMODE         = local.iam_compatmode
    JR_MAXJOBS            = 3
    JR_LOGGERLEVEL        = "-1"
    JR_ATLOGGERLEVEL      = "-1"
    JR_EXTLOGGERLEVEL     = "-1"
    JR_AGENTVERSION       = "1.0.0"
    JR_FEATUREFLAGS       = "AgentRegistration:true"
  }

  depends_on = [kubernetes_namespace.namespace]
}

//creating image pull secret for jobrunner
resource "kubernetes_secret" "schematics-jobrunner-image-secret" {
  metadata {
    name      = "schematics-jobrunner-image-secret"
    namespace = "schematics-job-runtime"
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


resource "kubernetes_service" "job_runner_loadbalancer" {
  metadata {
    name      = "job-runner-loadbalancer"
    namespace = "schematics-job-runtime"
  }

  spec {
    port {
      name        = "job-runner-port"
      port        = 2021
      target_port = "job-runner-port"
    }

    selector = {
      app = "jobrunner"
    }
    // type = "LoadBalancer" // Not needed, since there is no outbound connection
  }

  depends_on = [kubernetes_namespace.namespace]
}

resource "kubernetes_deployment" "jobrunner" {
  timeouts {
    create = "60m"
    delete = "60m"
  }
  metadata {
    name      = "jobrunner"
    namespace = "schematics-job-runtime"

    labels = {
      app = "jobrunner"
    }
    annotations = {
      "kubernetes.io/change-cause" = "job_runner_1.0"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "jobrunner"
      }
    }

    template {
      metadata {
        labels = {
          app = "jobrunner"

          build = "job-runner-1"
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
          image   = "icr.io/schematics-remote/ubi-minimal:8.6"
          command = ["sh", "-c", "chmod -R a+rwx /var/log/at"]

          volume_mount {
            name       = "at-events"
            mount_path = "/var/log/at"
          }
        }

        init_container {
          name    = "fix-permissions-extlog"
          image   = "icr.io/schematics-remote/ubi-minimal:8.6"
          command = ["sh", "-c", "chmod -R a+rwx /var/log/schematics"]

          volume_mount {
            name       = "ext-logs"
            mount_path = "/var/log/schematics"
          }
        }

        image_pull_secrets {
          name = "schematics-jobrunner-image-secret"
        }

        container {
          name  = "jobrunner"
          image = local.schematics_jobrunner_image

          port {
            name           = "job-runner-port"
            container_port = 2021
          }

          env_from {
            config_map_ref {
              name = "schematics-jobrunner-config"
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

  depends_on = [kubernetes_service.job_runner_loadbalancer, kubernetes_config_map.runtime_job_configmap, kubernetes_secret.schematics-jobrunner-image-secret]
}
