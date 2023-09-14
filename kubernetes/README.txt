https://vsupalov.com/multiple-kubectl-versions/

kubectl
  https://kubernetes.io/releases/
  https://kubernetes.io/docs/tasks/tools/#kubectl
  https://kubernetes.io/docs/reference/kubectl/
  https://kubernetes.io/releases/version-skew-policy/
  https://github.com/kubernetes/kubernetes/tree/master/CHANGELOG

kube-apiserver is at 1.28
kubelet is supported at 1.28, 1.27, 1.26, and 1.25

helm
  https://helm.sh/docs/intro/install/
  https://github.com/helm/helm/releases
  https://helm.sh/docs/topics/version_skew/
  https://helm.sh/docs/helm/helm/
  https://helm.sh/docs/helm/helm_completion_bash/
  
  
  exec kubectl-${HELM_VERSION} "$@"

~/.kube/clusters/{cluster_name} 
└ config
└ env
  KUBECTL_VERSION=a.b.c
  HELM_VERSION=a.b.c
└ kubectl-completion.bash
└ helm-completion.bash

TODO: copy context/namespace to new terminal tab