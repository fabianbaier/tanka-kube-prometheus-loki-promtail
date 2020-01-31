(import 'ksonnet-util/kausal.libsonnet') +
(import 'config.libsonnet') +
(import 'loki-config.libsonnet') +
(import 'images.libsonnet') +
{
  local container = $.core.v1.container,
  local containerPort = $.core.v1.containerPort,
  local deployment = $.apps.v1.deployment,
  local policyRule = $.rbac.v1beta1.policyRule,
  local psp = $.extensions.v1beta1.podSecurityPolicy,
  local pvc = $.core.v1.persistentVolumeClaim,
  local role = $.rbac.v1.role,
  local roleBinding = $.rbac.v1.roleBinding,
  local secret = $.core.v1.secret,
  local service = $.core.v1.service,
  local serviceAccount = $.core.v1.serviceAccount,
  local statefulSet = $.apps.v1beta2.statefulSet,
  local subject = $.rbac.v1beta1.subject,
  local volumeMount = $.core.v1.volumeMount,
  local volume = $.core.v1.volume,

  loki_psp:
    psp.new() +
    psp.mixin.metadata.withLabels($._config.loki.labels) +
    psp.mixin.metadata.withName($._config.loki.name) +
    psp.mixin.metadata.withNamespace($._config.loki.namespace) +
    psp.mixin.spec.withAllowPrivilegeEscalation($._config.loki.podSecurityPolicy.allowPrivilegeEscalation) +
    psp.mixin.spec.fsGroup.withRanges($._config.loki.podSecurityPolicy.ranges) +
      // idRange.new() +
      //.withMax($._config.loki.podSecurityPolicy.rangeMax)
      //.withMin($._config.loki.podSecurityPolicy.rangeMin),
    psp.mixin.spec.fsGroup.withRule('MustRunAs') +
    psp.mixin.spec.withReadOnlyRootFilesystem($._config.loki.podSecurityPolicy.readOnlyRootFilesystem) +
    psp.mixin.spec.withRequiredDropCapabilities('ALL') +
    psp.mixin.spec.runAsUser.withRule('MustRunAsNonRoot') +
    psp.mixin.spec.seLinux.withRule('RunAsAny') +
    psp.mixin.spec.supplementalGroups.withRanges($._config.loki.podSecurityPolicy.ranges) +
    psp.mixin.spec.supplementalGroups.withRule('MustRunAs') +
    psp.mixin.spec.withVolumes(['configMap', 'emptyDir', 'persistentVolumeClaim', 'secret']),

  loki_role:
    role.new() +
    role.mixin.metadata.withLabels($._config.loki.labels) +
    role.mixin.metadata.withName($._config.loki.name) +
    role.mixin.metadata.withNamespace($._config.loki.namespace) +
    role.withRules(policyRule.new() +
      policyRule.withApiGroups('extensions') +
      policyRule.withResourceNames($._config.loki.name) +
      policyRule.withResources('podsecuritypolicies') +
      policyRule.withVerbs('use')
    ),

  loki_role_binding:
    roleBinding.new() +
    roleBinding.mixin.metadata.withLabels($._config.loki.labels) +
    roleBinding.mixin.metadata.withName($._config.loki.name) +
    roleBinding.mixin.metadata.withNamespace($._config.loki.namespace) +
    roleBinding.mixin.roleRef.withApiGroup('rbac.authorization.k8s.io') +
    roleBinding.mixin.roleRef.withKind('Role') +
    roleBinding.mixin.roleRef.withName($._config.loki.name) +
    roleBinding.withSubjects(
      subject.new() +
      subject.withKind('ServiceAccount') +
      subject.withName($._config.loki.name)
    ),

  loki_secret:
    secret.new($._config.loki.name).withData(
      {
          'config.yaml': std.base64(std.toString($.loki_config)),
      }
    ) +
    secret.mixin.metadata.withNamespace($._config.loki.namespace),

  loki_container::
    container.new('loki', $._images.loki) +
    container.mixin.livenessProbe.withFailureThreshold(3) +
    container.mixin.livenessProbe.httpGet
      .withPath('/ready')
      .withScheme('HTTP') +
    container.mixin.livenessProbe.httpGet
      .withPort('http-metrics') +
    container.mixin.livenessProbe.withInitialDelaySeconds(45) +
    container.mixin.livenessProbe.withPeriodSeconds(10) +
    container.mixin.livenessProbe.withSuccessThreshold(1) +
    container.mixin.livenessProbe.withTimeoutSeconds(1) +
    container.withPorts([
      containerPort.newNamed(name='http-metrics', containerPort=3100)
        .withProtocol('TCP')]) +
    container.mixin.readinessProbe.withFailureThreshold(3) +
    container.mixin.readinessProbe.httpGet
      .withPath('/ready')
      .withScheme('HTTP') +
    container.mixin.readinessProbe.httpGet
      .withPort('http-metrics') +
    container.mixin.readinessProbe.withInitialDelaySeconds(45) +
    container.mixin.readinessProbe.withPeriodSeconds(10) +
    container.mixin.readinessProbe.withSuccessThreshold(1) +
    container.mixin.readinessProbe.withTimeoutSeconds(1) +
    container.mixin.securityContext.mixinInstance(
      $._config.loki.securityContext,
      ) +
    container.withVolumeMountsMixin(
      volumeMount.new('config', '/etc/loki'),
    ) +
    container.withVolumeMountsMixin(
      volumeMount.new('storage', '/data'),
    ) +
    container.withArgsMixin(
      $.util.mapToFlags($._config.loki.commonArgs),
    ),

  loki_service_headless:
    $.util.serviceFor($.loki_stateful_set, nameFormat="%(port)s") +
    service.mixin.metadata.withLabels($._config.loki.labels) +
    service.mixin.metadata.withName($._config.loki.name+'-headless') +
    service.mixin.metadata.withNamespace($._config.loki.namespace) +
    service.mixin.spec.withClusterIp('None') +
    service.mixin.spec.withSessionAffinity('None') +
    service.mixin.spec.withType('ClusterIP'),

  loki_service:
    $.util.serviceFor($.loki_stateful_set, nameFormat="%(port)s") +
    service.mixin.metadata.withLabels($._config.loki.labels) +
    service.mixin.metadata.withName($._config.loki.name) +
    service.mixin.metadata.withNamespace($._config.loki.namespace) +
    service.mixin.spec.withClusterIp('None') +
    service.mixin.spec.withSessionAffinity('None') +
    service.mixin.spec.withType('ClusterIP'),  

  loki_service_account:
    serviceAccount.new($._config.loki.name),

  loki_stateful_set:
    statefulSet.new($._config.loki.name) +
    statefulSet.mixin.metadata.withLabels($._config.loki.labels) + 
    statefulSet.mixin.spec.withPodManagementPolicy($._config.loki.podManagementPolicy) +
    statefulSet.mixin.spec.withReplicas($._config.loki.replicas) +
    statefulSet.mixin.spec.withRevisionHistoryLimit($._config.loki.revisionHistoryLimit) +
    statefulSet.mixin.spec.selector.withMatchLabels($._config.loki.labels) +
    statefulSet.mixin.spec.withServiceName($._config.loki.name+'-headless') +
    statefulSet.mixin.spec.template.metadata.withAnnotations($._config.loki.annotations) + 
    statefulSet.mixin.spec.template.metadata.withLabels($._config.loki.labels) +
    statefulSet.mixin.spec.template.spec.withContainers($.loki_container) +
    statefulSet.mixin.spec.template.spec.withDnsPolicy($._config.loki.dnsPolicy) +
    statefulSet.mixin.spec.template.spec.withRestartPolicy($._config.loki.restartPolicy) +
    statefulSet.mixin.spec.template.spec.securityContext.withFsGroup(10001) + 
    statefulSet.mixin.spec.template.spec.securityContext.withRunAsGroup(10001) +
    statefulSet.mixin.spec.template.spec.securityContext.withRunAsNonRoot(true) +
    statefulSet.mixin.spec.template.spec.securityContext.withRunAsUser(10001) +
    statefulSet.mixin.spec.template.spec.withServiceAccount($._config.loki.name) +
    statefulSet.mixin.spec.template.spec.withTerminationGracePeriodSeconds($._config.loki.terminationGracePeriodSeconds) +
    statefulSet.mixin.spec.template.spec.withVolumesMixin([
      volume.fromSecret('config', $._config.loki.name),
    ]) +
    statefulSet.mixin.spec.withVolumeClaimTemplates(
      pvc.new() +
      pvc.mixin.metadata.withName('storage') +
      pvc.mixin.metadata.withNamespace($._config.loki.namespace) +
      pvc.mixin.spec.withAccessModes('ReadWriteOnce') +
      pvc.mixin.spec.resources.withRequests({ storage: '10Gi' }),
    ), 

}   