{
  _config+:: {
    promtail: {
      annotations: {
        'prometheus.io/port': 'http-metrics',
        'prometheus.io/scrape': "true",
      },
      commonArgs: {
        'config.file': '/etc/promtail/config.yaml',
        'client.url': 'http://'+ $._config.loki.name +'.' + $._config.loki.namespace +':3100/loki/api/v1/push'
      },
      dnsPolicy: 'ClusterFirst',
      name: 'promtailo',
      namespace: 'monitoring-dev',
      labels: {
          'app': 'promtail',
          'name': $._config.promtail.name,
        },
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
      restartPolicy: 'Always',
      revisionHistoryLimit: 10,
      securityContext: {
        'readOnlyRootFilesystem': true,
        'runAsGroup': 0,
        'runAsUser': 0,
      },
      terminationGracePeriodSeconds: 30,
    },
  },
}