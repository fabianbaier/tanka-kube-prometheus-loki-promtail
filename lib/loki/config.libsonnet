{
  _config+:: {
    loki: {
      name: 'loki',
      namespace: 'monitoring-dev',
      cluster: error 'must define cluster',

      annotations: {
        'prometheus.io/port': 'http-metrics',
        'prometheus.io/scrape': "true",
      },
      commonArgs: {
        'config.file': '/etc/loki/config.yaml',
      },
      dnsPolicy: 'ClusterFirst',
      labels: {
        'app': 'loki',
        'name': $._config.loki.name,
      },
      podManagementPolicy: 'OrderedReady',
      podSecurityPolicy: {
        allowPrivilegeEscalation: false,
        ranges: {
          max: 65535,
          min: 1
        },
        rangeMax: 65535,
        rangeMin: 1,
        readOnlyRootFilesystem: true,
      },
      replicas: 1,
      revisionHistoryLimit: 10,
      restartPolicy: 'Always',
      securityContext: {
        'readOnlyRootFilesystem': true,
      },
      terminationGracePeriodSeconds: 4800,
    },
  },
}