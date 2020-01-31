{
  promtail_config:: {
    "client": {
        "backoff_config": {
          "maxbackoff": "5s",
          "maxretries": 20,
          "minbackoff": "100ms"
        },
        "batchsize": 102400,
        "batchwait": "1s",
        "external_labels": {},
        "timeout": "10s"
    },
    "positions": {
        "filename": "/run/promtail/positions.yaml"
    },
    "server": {
        "http_listen_port": 3101
    },
    "target_config": {
        "sync_period": "10s"
    },
    "scrape_configs": [
        {
          "job_name": "kubernetes-pods-name",
          "pipeline_stages": [
              {
                "docker": {}
              }
          ],
          "kubernetes_sd_configs": [
              {
                "role": "pod"
              }
          ],
          "relabel_configs": [
              {
                "source_labels": [
                    "__meta_kubernetes_pod_label_name"
                ],
                "target_label": "__service__"
              },
              {
                "source_labels": [
                    "__meta_kubernetes_pod_node_name"
                ],
                "target_label": "__host__"
              },
              {
                "action": "drop",
                "regex": "",
                "source_labels": [
                    "__service__"
                ]
              },
              {
                "action": "labelmap",
                "regex": "__meta_kubernetes_pod_label_(.+)"
              },
              {
                "action": "replace",
                "replacement": "$1",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_namespace",
                    "__service__"
                ],
                "target_label": "job"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_namespace"
                ],
                "target_label": "namespace"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_name"
                ],
                "target_label": "instance"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "container_name"
              },
              {
                "replacement": "/var/log/pods/*$1/*.log",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_pod_uid",
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "__path__"
              }
          ]
        },
        {
          "job_name": "kubernetes-pods-app",
          "pipeline_stages": [
              {
                "docker": {}
              }
          ],
          "kubernetes_sd_configs": [
              {
                "role": "pod"
              }
          ],
          "relabel_configs": [
              {
                "action": "drop",
                "regex": ".+",
                "source_labels": [
                    "__meta_kubernetes_pod_label_name"
                ]
              },
              {
                "source_labels": [
                    "__meta_kubernetes_pod_label_app"
                ],
                "target_label": "__service__"
              },
              {
                "source_labels": [
                    "__meta_kubernetes_pod_node_name"
                ],
                "target_label": "__host__"
              },
              {
                "action": "drop",
                "regex": "",
                "source_labels": [
                    "__service__"
                ]
              },
              {
                "action": "labelmap",
                "regex": "__meta_kubernetes_pod_label_(.+)"
              },
              {
                "action": "replace",
                "replacement": "$1",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_namespace",
                    "__service__"
                ],
                "target_label": "job"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_namespace"
                ],
                "target_label": "namespace"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_name"
                ],
                "target_label": "instance"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "container_name"
              },
              {
                "replacement": "/var/log/pods/*$1/*.log",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_pod_uid",
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "__path__"
              }
          ]
        },
        {
          "job_name": "kubernetes-pods-direct-controllers",
          "pipeline_stages": [
              {
                "docker": {}
              }
          ],
          "kubernetes_sd_configs": [
              {
                "role": "pod"
              }
          ],
          "relabel_configs": [
              {
                "action": "drop",
                "regex": ".+",
                "separator": "",
                "source_labels": [
                    "__meta_kubernetes_pod_label_name",
                    "__meta_kubernetes_pod_label_app"
                ]
              },
              {
                "action": "drop",
                "regex": "[0-9a-z-.]+-[0-9a-f]{8,10}",
                "source_labels": [
                    "__meta_kubernetes_pod_controller_name"
                ]
              },
              {
                "source_labels": [
                    "__meta_kubernetes_pod_controller_name"
                ],
                "target_label": "__service__"
              },
              {
                "source_labels": [
                    "__meta_kubernetes_pod_node_name"
                ],
                "target_label": "__host__"
              },
              {
                "action": "drop",
                "regex": "",
                "source_labels": [
                    "__service__"
                ]
              },
              {
                "action": "labelmap",
                "regex": "__meta_kubernetes_pod_label_(.+)"
              },
              {
                "action": "replace",
                "replacement": "$1",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_namespace",
                    "__service__"
                ],
                "target_label": "job"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_namespace"
                ],
                "target_label": "namespace"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_name"
                ],
                "target_label": "instance"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "container_name"
              },
              {
                "replacement": "/var/log/pods/*$1/*.log",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_pod_uid",
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "__path__"
              }
          ]
        },
        {
          "job_name": "kubernetes-pods-indirect-controller",
          "pipeline_stages": [
              {
                "docker": {}
              }
          ],
          "kubernetes_sd_configs": [
              {
                "role": "pod"
              }
          ],
          "relabel_configs": [
              {
                "action": "drop",
                "regex": ".+",
                "separator": "",
                "source_labels": [
                    "__meta_kubernetes_pod_label_name",
                    "__meta_kubernetes_pod_label_app"
                ]
              },
              {
                "action": "keep",
                "regex": "[0-9a-z-.]+-[0-9a-f]{8,10}",
                "source_labels": [
                    "__meta_kubernetes_pod_controller_name"
                ]
              },
              {
                "action": "replace",
                "regex": "([0-9a-z-.]+)-[0-9a-f]{8,10}",
                "source_labels": [
                    "__meta_kubernetes_pod_controller_name"
                ],
                "target_label": "__service__"
              },
              {
                "source_labels": [
                    "__meta_kubernetes_pod_node_name"
                ],
                "target_label": "__host__"
              },
              {
                "action": "drop",
                "regex": "",
                "source_labels": [
                    "__service__"
                ]
              },
              {
                "action": "labelmap",
                "regex": "__meta_kubernetes_pod_label_(.+)"
              },
              {
                "action": "replace",
                "replacement": "$1",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_namespace",
                    "__service__"
                ],
                "target_label": "job"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_namespace"
                ],
                "target_label": "namespace"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_name"
                ],
                "target_label": "instance"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "container_name"
              },
              {
                "replacement": "/var/log/pods/*$1/*.log",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_pod_uid",
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "__path__"
              }
          ]
        },
        {
          "job_name": "kubernetes-pods-static",
          "pipeline_stages": [
              {
                "docker": {}
              }
          ],
          "kubernetes_sd_configs": [
              {
                "role": "pod"
              }
          ],
          "relabel_configs": [
              {
                "action": "drop",
                "regex": "",
                "source_labels": [
                    "__meta_kubernetes_pod_annotation_kubernetes_io_config_mirror"
                ]
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_label_component"
                ],
                "target_label": "__service__"
              },
              {
                "source_labels": [
                    "__meta_kubernetes_pod_node_name"
                ],
                "target_label": "__host__"
              },
              {
                "action": "drop",
                "regex": "",
                "source_labels": [
                    "__service__"
                ]
              },
              {
                "action": "labelmap",
                "regex": "__meta_kubernetes_pod_label_(.+)"
              },
              {
                "action": "replace",
                "replacement": "$1",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_namespace",
                    "__service__"
                ],
                "target_label": "job"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_namespace"
                ],
                "target_label": "namespace"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_name"
                ],
                "target_label": "instance"
              },
              {
                "action": "replace",
                "source_labels": [
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "container_name"
              },
              {
                "replacement": "/var/log/pods/*$1/*.log",
                "separator": "/",
                "source_labels": [
                    "__meta_kubernetes_pod_annotation_kubernetes_io_config_mirror",
                    "__meta_kubernetes_pod_container_name"
                ],
                "target_label": "__path__"
              }
          ]
        }
    ]
  }
}