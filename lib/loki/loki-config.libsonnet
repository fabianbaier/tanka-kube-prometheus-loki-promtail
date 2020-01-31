{
  loki_config:: {
    auth_enabled: false,

    ingester: {
      chunk_idle_period: '5m',
      chunk_block_size: 262144,
      chunk_retain_period: '1m',
      max_transfer_retries: 1,
      lifecycler: {
        address: '127.0.0.1',
        final_sleep: '0s',
        ring: {
          kvstore: { store: 'inmemory' },
          replication_factor: 1,
        },
      },
    },

    limits_config: {
      enforce_metric_name: false,
      reject_old_samples: true,
      reject_old_samples_max_age: '168h',
    },

    schema_config: {
      configs: [{
        from: '2018-04-15',
        store: 'boltdb',
        object_store: 'filesystem',
        schema: 'v9',
        index: {
          prefix: 'index_',
          period: '168h',
        }
      }],
    },

    server: {
      graceful_shutdown_timeout: '5s',
      grpc_server_max_recv_msg_size: 1024 * 1024 * 64,
      http_listen_port: 3100,
      http_server_idle_timeout: '120s',
    },

    storage_config: {
      boltdb: {
        directory: '/data/loki/index',
      },

      filesystem: {
        directory: '/data/loki/chunks',
      },
    },

    chunk_store_config: {
      max_look_back_period: 0,
    },

    table_manager: {
      retention_deletes_enabled: false,
      retention_period: 0,
    },
  },
}