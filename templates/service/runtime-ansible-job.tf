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

resource "kubernetes_config_map" "runtime_ansible_job_configmap" {
  metadata {
    name      = "schematics-runtime-ansible-job-config"
    namespace = "schematics-runtime"
  }

  data = {
    ANSIBLE_JOB_HTTPADDR = ""
    ANSIBLE_JOB_HTTPPORT = 3006
    ANSIBLE_JOB_KEEPWORKFILES = true
    ANSIBLE_JOB_SINGLEACTIONMODE = true
    ANSIBLE_JOB_LOGGERLEVEL = "0"
    ANSIBLE_JOB_ATLOGGERLEVEL = "-1"
    ANSIBLE_JOB_EXTLOGGERLEVEL = "-1"
    ANSIBLE_JOB_EXTLOGPATH = "/var/log/schematics/%s.log"
    ANSIBLE_JOB_WHITELISTEXTN = ".tf,.tfvars,.md,.yaml,.sh,.txt,.yml,.html,.gitignore,.tf.json,license,.js,.pub,.service,_rsa,.py,.json,.tpl,.cfg,.ps1,.j2,.zip,.conf,.crt,.key,.der,.jacl,.properties,.cer,.pem,.tmpl,.netrc"
    ANSIBLE_JOB_ANSIBLEACTIONWHITELISTEXTN = ".tf,.tfvars,.md,.yaml,.sh,.txt,.yml,.html,.gitignore,.tf.json,license,.js,.pub,.service,_rsa,.py,.json,.tpl,.cfg,.ps1,.j2,.zip,.conf,.crt,.key,.der,.cer,.pem,.bash,.tmpl"
    ANSIBLE_JOB_BLACKLISTEXTN = ".php5,.pht,.phtml,.shtml,.asa,.asax,.swf,.xap,.tfstate,.tfstate.backup,.exe"
    IBMCLOUD_ACCOUNT_MANAGEMENT_API_ENDPOINT = ""
    IBMCLOUD_CF_API_ENDPOINT = ""
    IBMCLOUD_CS_API_ENDPOINT = ""
    IBMCLOUD_CR_API_ENDPOINT = ""
    IBMCLOUD_CIS_API_ENDPOINT = ""
    IBMCLOUD_GS_API_ENDPOINT = ""
    IBMCLOUD_GT_API_ENDPOINT = ""
    IBMCLOUD_IAM_API_ENDPOINT = ""
    IBMCLOUD_IAMPAP_API_ENDPOINT = ""
    IBMCLOUD_ICD_API_ENDPOINT = ""
    IBMCLOUD_MCCP_API_ENDPOINT = ""
    IBMCLOUD_RESOURCE_MANAGEMENT_API_ENDPOINT = ""
    IBMCLOUD_RESOURCE_CONTROLLER_API_ENDPOINT = ""
    IBMCLOUD_RESOURCE_CATALOG_API_ENDPOINT = ""
    IBMCLOUD_UAA_ENDPOINT = ""
    IBMCLOUD_CSE_ENDPOINT = ""
    IBMCLOUD_IS_API_ENDPOINT = ""
    IBMCLOUD_IS_NG_API_ENDPOINT = ""
    IBMCLOUD_COS_CONFIG_ENDPOINT = ""
    IBMCLOUD_API_GATEWAY_ENDPOINT = ""
    IBMCLOUD_DL_API_ENDPOINT = ""
    IBMCLOUD_DL_PROVIDER_API_ENDPOINT = ""
    IBMCLOUD_TG_API_ENDPOINT = ""
    IBMCLOUD_HPCS_API_ENDPOINT = ""
    IBMCLOUD_FUNCTIONS_API_ENDPOINT = ""
    IBMCLOUD_SATELLITE_API_ENDPOINT = ""
    IBMCLOUD_ENTERPRISE_API_ENDPOINT = ""
    IBMCLOUD_PUSH_API_ENDPOINT = ""
    IBMCLOUD_CATALOG_MANAGEMENT_API_ENDPOINT = ""
    IBMCLOUD_HPCS_TKE_ENDPOINT = ""
    ANSIBLE_JOB_ENABLETLS = false
    ANSIBLE_JOB_OPPONENTSCA = ""
    #ANSIBLE_JOB_CERTPEM = ""
    #ANSIBLE_JOB_KEYPEM = ""
  }

  depends_on = [kubernetes_namespace.namespace]

}

resource "kubernetes_config_map" "runtime_adapter_job_configmap" {
  metadata {
    name      = "schematics-runtime-adapter-job-config"
    namespace = "schematics-runtime"
  }

  data = {
    ADAPTER_HTTPPORT = "4001"
    ADAPTER_MAXRETRIES = ""
    ADAPTER_LOCATION = "us-south"
    ADAPTER_LOGGERLEVEL = "-1"
    ADAPTER_ATLOGGERLEVEL = "-1"
    ADAPTER_EXTLOGGERLEVEL = "-1"
    ADAPTER_EXTLOGPATH = "/var/log/schematics/%s.log"
    ADAPTER_PLUGINHOME = "/go/src/github.ibm.com/blueprint/schematics-data-adapter/plugins"
  }

  depends_on = [kubernetes_namespace.namespace]

}

resource "kubernetes_service" "ansible_job_service" {
  metadata {
    name      = "ansible-job-service"
    namespace = "schematics-runtime"
  }

  spec {
    port {
      name        = "grpc-job"
      port        = 3006
      target_port = "grpc-job"
    }

    selector = {
      app = "runtime-ansible-job"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_namespace.namespace]
}

//creating image pull secret for ansible job
// TODO Remove this once the Ansible and adpater is released
resource "kubernetes_secret" "schematics-ansible-secret" {
  metadata {
    name      = "schematics-runtime-ansible-job-image-secret"
    namespace = "schematics-runtime"
  }
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "us.icr.io" = {
          auth = base64encode("iamapikey:${var.ansible_pull_ibmcloud_api_key}")
        }
      }
    })
  }
  type = "kubernetes.io/dockerconfigjson"
  depends_on = [kubernetes_namespace.namespace]
}


resource "kubernetes_deployment" "runtime_ansible_job" {
  timeouts {
    create = "60m"
    delete = "60m"
  }
  metadata {
    name      = "runtime-ansible-job"
    namespace = "schematics-runtime"


    labels = {
      app = "runtime-ansible-job"
    }

    annotations = {
      "kubernetes.io/change-cause" = "schematics-ansible-job_1338"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "runtime-ansible-job"
      }
    }

    template {
      metadata {
        labels = {
          app = "runtime-ansible-job"
          build = "ansible-job-1338"
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
          name = "schematics-runtime-ansible-job-image-secret"
        }

        container {
          name  = "runtime-ansible-job"
          image = local.schematics_runtime_ansible_job_image
          port {
            name           = "grpc-job"
            container_port = 3006
          }

          env_from {
            config_map_ref {
              name = "schematics-runtime-ansible-job-config"
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
        container {
          name  = "adapter"
          image = local.schematics_runtime_adapter_job_image

          env_from {
            config_map_ref {
              name = "schematics-runtime-adapter-job-config"
            }
          }

          port {
            name           = "http-adapter"
            container_port = 4001
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
        }

        restart_policy                   = "Always"
        termination_grace_period_seconds = 180000
      }
    }
    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "1"
        max_surge       = "1"
      }
    }

    revision_history_limit = 5
  }

  depends_on = [kubernetes_service.job_service, kubernetes_config_map.runtime_ansible_job_configmap,kubernetes_config_map.runtime_adapter_job_configmap, kubernetes_namespace.namespace]
}

##############################################################################