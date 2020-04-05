resource "kubernetes_service_account" "k8s-service-account" {
  metadata {
    name = var.k8s-service-account-name
  }

  automount_service_account_token = "true"
}


resource "kubernetes_role_binding" "k8s-role-binding" {
  metadata {
    name      = "k8s-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.k8s-service-account-name
  }
  subject {
    kind      = "User"
    name      = data.terraform_remote_state.current-project.outputs.google_service_account_project-service-account_email
  }
  subject {
    kind = "User"
    name = var.automation-service-account
  }
}
