local loki = import 'loki/loki.libsonnet';
local promtail = import 'promtail/promtail.libsonnet';
local kp = import 'kubeprometheus/kubeprometheus.libsonnet';

loki + promtail + kp + {
  ns:
    $.core.v1.namespace.new($._config.loki.namespace),
} 
