# Deploy a simple voting application that uses redis as its backend
job "voter" {
  datacenters = ["us-west-2a", "us-west-2b", "us-west-2c"]

  # As we have 3 worker nodes, we'll spin up 3 voter instances to
  # verify they are all talking to the same redis
  group "voter" {
    count = 3

    network {
      mode = "bridge"

      # Map the host port 80 to the container port 80
      port "http" {
	static = 80
	to = 80
      }
    }

    # Configure the voter HTTP service
    service {
      name = "voter"
      tags = ["global", "app", "frontend"]
      port = "80"

      connect {
	sidecar_service {
	  # Set up a proxy connection to redis
	  proxy {
	    upstreams {
	      destination_name = "redis"
	      local_bind_port = 6379
	    }
	  }
	}
      }
    }

    task "voter" {
      driver = "docker"

      config {
        image = "mcr.microsoft.com/azuredocs/azure-vote-front:v2"
      }

      # The image requires a host/IP address and assumes the default port
      env {
        REDIS = "${NOMAD_UPSTREAM_IP_redis}"
      }
    }
  }
}
