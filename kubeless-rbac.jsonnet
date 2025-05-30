# Add RBAC role and binding on top of kubeless.jsonnet, to allow
# kubeless controller to deploy/update/etc functions on any namespace
local k = import "ksonnet.beta.1/k.libsonnet";
local objectMeta = k.core.v1.objectMeta;

local kubeless = import "kubeless.jsonnet";
local controller_account = kubeless.controller_account;
local controller_roles = [
  {
    apiGroups: [""],
    resources: ["services", "configmaps"],
    verbs: ["create", "get", "delete", "list", "update", "patch"],
  },
  {
    apiGroups: ["apps", "extensions"],
    resources: ["deployments"],
    verbs: ["create", "get", "delete", "list", "update", "patch"],
  },
  {
    apiGroups: [""],
    resources: ["pods"],
    verbs: ["list", "delete"],
  },
  {
    apiGroups: ["k8s.io"],
    resources: ["functions"],
    verbs: ["get", "list", "watch"],
  },
  {
    apiGroups: ["batch"],
    resources: ["cronjobs"],
    verbs: ["create", "get", "delete", "list", "update", "patch"],
  },
  {
    apiGroups: ["autoscaling"],
    resources: ["horizontalpodautoscalers"],
    verbs: ["create", "get", "delete", "list", "update", "patch"],
  },
  {
    apiGroups: ["monitoring.coreos.com"],
    resources: ["alertmanagers", "prometheuses", "servicemonitors"],
    verbs: ["*"],
  },
];

local controllerAccount = kubeless.controllerAccount;

local clusterRole(name, rules) = {
    apiVersion: "rbac.authorization.k8s.io/v1beta1",
    kind: "ClusterRole",
    metadata: objectMeta.name(name),
    rules: rules,
};

local clusterRoleBinding(name, role, subjects) = {
    apiVersion: "rbac.authorization.k8s.io/v1beta1",
    kind: "ClusterRoleBinding",
    metadata: objectMeta.name(name),
    subjects: [{kind: s.kind, namespace: s.metadata.namespace, name: s.metadata.name} for s in subjects],
    roleRef: {kind: role.kind, apiGroup: "rbac.authorization.k8s.io", name: role.metadata.name},
};

local controllerClusterRole = clusterRole(
  "kubeless-controller-deployer", controller_roles);

local controllerClusterRoleBinding = clusterRoleBinding(
  "kubeless-controller-deployer", controllerClusterRole, [controllerAccount]
);

kubeless + {
  controllerClusterRole: controllerClusterRole,
  controllerClusterRoleBinding: controllerClusterRoleBinding,
}
