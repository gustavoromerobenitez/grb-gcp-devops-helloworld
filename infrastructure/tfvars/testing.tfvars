region = "europe-west2"
zone = "europe-west2-a"
google-provider-version = "3.5.0"
# billing-account = "" # Useful for FinOps # SECRET Should be read from a bucket

container-cluster-name = "${var.project-name}-k8s-cluster-1"
container-cluster-cidr-range = "10.1.0.0/20"
container-cluster-subnetwork-name = "${var.project-name}-k8s-subnetwork"
container-cluster-pods-secondary-range-name = "${var.project-name}-k8s-pods-secondary-range"
container-cluster-pods-secondary-range-cidr = "10.120.0.0/24"
container-cluster-services-secondary-range-name = "${var.project-name}-k8s-services-secondary-range"
container-cluster-services-secondary-range-cidr = "10.120.1.0/24"
