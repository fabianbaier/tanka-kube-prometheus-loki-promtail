(import 'ksonnet-util/kausal.libsonnet') +
(import 'config.libsonnet') +
(import 'promtail-config.libsonnet') +
(import 'images.libsonnet') +
{
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local clusterRole = $.rbac.v1.clusterRole,
  local clusterRoleBinding = $.rbac.v1.clusterRoleBinding,
  local configMap = $.core.v1.configMap,
  local daemonSet = $.extensions.v1beta1.daemonSet,
  local policyRule = $.rbac.v1beta1.policyRule,
  local psp = $.extensions.v1beta1.podSecurityPolicy,
  local role = $.rbac.v1.role,
  local roleBinding = $.rbac.v1.roleBinding,
  local serviceAccount = $.core.v1.serviceAccount,
  local subject = $.rbac.v1beta1.subject,
  local volumeMount = $.core.v1.volumeMount,
  local volume = $.core.v1.volume,



  promtail_cluster_role:
    clusterRole.new() +
    clusterRole.mixin.metadata.withLabels($._config.promtail.labels) +
    clusterRole.mixin.metadata.withName($._config.promtail.name) +
    clusterRole.mixin.metadata.withNamespace($._config.promtail.namespace) +
    clusterRole.withRules(policyRule.new() +
      policyRule.withApiGroups('') +
      policyRule.withResources(['nodes', 'nodes/proxy', 'services', 'endpoints', 'pods']) +
      policyRule.withVerbs(['get', 'list', 'watch']),
    ),

  
  promtail_cluster_role_binding:
    clusterRoleBinding.new() +
    clusterRoleBinding.mixin.metadata.withLabels($._config.promtail.labels) +
    clusterRoleBinding.mixin.metadata.withName($._config.promtail.name) +
    clusterRoleBinding.mixin.metadata.withNamespace($._config.promtail.namespace) +
    clusterRoleBinding.mixin.roleRef.withApiGroup('rbac.authorization.k8s.io') +
    clusterRoleBinding.mixin.roleRef.withKind('ClusterRole') +
    clusterRoleBinding.mixin.roleRef.withName($._config.promtail.name) +
    clusterRoleBinding.withSubjects(
      subject.new() +
      subject.withKind('ServiceAccount') +
      subject.withName($._config.promtail.name) +
      subject.withNamespace($._config.promtail.namespace)
    ),

  promtail_config_map:
    configMap.new($._config.promtail.name+'-config') +
    configMap.mixin.metadata.withNamespace($._config.promtail.namespace) +
    configMap.withData({
      'config.yaml': $.util.manifestYaml($.promtail_config),
    }),

  promtail_container::
    container.new('promtail', $._images.promtail) +
    container.withArgsMixin(
      $.util.mapToFlags($._config.promtail.commonArgs),
    ) +
    container.withEnv([
      container.envType.fromFieldPath('HOSTNAME', 'spec.nodeName'),
    ]) +
    container.withPorts([
      containerPort.newNamed(name='http-metrics', containerPort=3101)
        .withProtocol('TCP')]) +
    container.mixin.readinessProbe.withFailureThreshold(5) +
    container.mixin.readinessProbe.httpGet
      .withPath('/ready')
      .withScheme('HTTP') +
    container.mixin.readinessProbe.httpGet
      .withPort('http-metrics') +
    container.mixin.readinessProbe.withInitialDelaySeconds(10) +
    container.mixin.readinessProbe.withPeriodSeconds(10) +
    container.mixin.readinessProbe.withSuccessThreshold(1) +
    container.mixin.readinessProbe.withTimeoutSeconds(1) +
    container.mixin.securityContext.mixinInstance(
      $._config.promtail.securityContext,
      ) +
    container.withVolumeMountsMixin(
      volumeMount.new('config', '/etc/promtail'),
    ) +
    container.withVolumeMountsMixin(
      volumeMount.new('run', '/run/promtail'),
    ) +
    container.withVolumeMountsMixin(
      volumeMount.new('docker', '/var/lib/docker/containers', readOnly=true),
    ) +
    container.withVolumeMountsMixin(
      volumeMount.new('pods', '/var/log/pods', readOnly=true),
    ),

  promtail_daemonset:
    daemonSet.new($._config.promtail.name, containers=$.promtail_container) +
    daemonSet.mixin.metadata.withLabels($._config.promtail.labels) +
    daemonSet.mixin.spec.withRevisionHistoryLimit($._config.promtail.revisionHistoryLimit) +
    daemonSet.mixin.spec.selector.withMatchLabels($._config.promtail.labels) +
    daemonSet.mixin.spec.template.metadata.withAnnotations($._config.promtail.annotations) + 
    daemonSet.mixin.spec.template.metadata.withLabels($._config.promtail.labels) +
    daemonSet.mixin.spec.template.spec.withContainers($.promtail_container) +
    daemonSet.mixin.spec.template.spec.withDnsPolicy($._config.promtail.dnsPolicy) +
    daemonSet.mixin.spec.template.spec.withRestartPolicy($._config.promtail.restartPolicy) +
    daemonSet.mixin.spec.template.spec.withServiceAccount($._config.promtail.name) +
    daemonSet.mixin.spec.template.spec.withServiceAccountName($._config.promtail.name) +
    daemonSet.mixin.spec.template.spec.withTerminationGracePeriodSeconds($._config.promtail.terminationGracePeriodSeconds) +
    daemonSet.mixin.spec.template.spec.withVolumesMixin([
      volume.fromConfigMap('config', $._config.promtail.name+'-config')
      .withDefaultMode(420),
      volume.fromHostPath('run', '/run/promtail')
      .withType(''),
      volume.fromHostPath('docker', '/var/lib/docker/containers')
      .withType(''),
      volume.fromHostPath('pods', '/var/log/pods')
      .withType('')
    ]) +
    daemonSet.mixin.spec.updateStrategy.rollingUpdate.withMaxUnavailable(1),

  promtail_psp:
    psp.new() +
    psp.mixin.metadata.withLabels($._config.promtail.labels) +
    psp.mixin.metadata.withName($._config.promtail.name) +
    psp.mixin.metadata.withNamespace($._config.promtail.namespace) +
    psp.mixin.spec.withAllowPrivilegeEscalation($._config.promtail.podSecurityPolicy.allowPrivilegeEscalation) +
    psp.mixin.spec.fsGroup.withRule('MustRunAs') +
    psp.mixin.spec.withReadOnlyRootFilesystem($._config.promtail.podSecurityPolicy.readOnlyRootFilesystem) +
    psp.mixin.spec.withRequiredDropCapabilities('ALL') +
    psp.mixin.spec.runAsUser.withRule('RunAsAny') +
    psp.mixin.spec.seLinux.withRule('RunAsAny') +
    psp.mixin.spec.supplementalGroups.withRule('RunAsAny') +
    psp.mixin.spec.withVolumes(['secret', 'configMap', 'hostPath']),

  promtail_role:
    role.new() +
    role.mixin.metadata.withLabels($._config.promtail.labels) +
    role.mixin.metadata.withName($._config.promtail.name) +
    role.mixin.metadata.withNamespace($._config.promtail.namespace) +
    role.withRules(policyRule.new() +
      policyRule.withApiGroups('extensions') +
      policyRule.withResourceNames($._config.promtail.name) +
      policyRule.withResources('podsecuritypolicies') +
      policyRule.withVerbs('use')
    ),

  promtail_role_binding:
    roleBinding.new() +
    roleBinding.mixin.metadata.withLabels($._config.promtail.labels) +
    roleBinding.mixin.metadata.withName($._config.promtail.name) +
    roleBinding.mixin.metadata.withNamespace($._config.promtail.namespace) +
    roleBinding.mixin.roleRef.withApiGroup('rbac.authorization.k8s.io') +
    roleBinding.mixin.roleRef.withKind('Role') +
    roleBinding.mixin.roleRef.withName($._config.promtail.name) +
    roleBinding.withSubjects(
      subject.new() +
      subject.withKind('ServiceAccount') +
      subject.withName($._config.promtail.name)
    ),  

  promtail_service_account:
    serviceAccount.new($._config.promtail.name),  
}   