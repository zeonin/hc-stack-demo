# Set up a barebones single instance of redis
job "redis" {
  datacenters = ["us-west-2a", "us-west-2b", "us-west-2c"]

  group "redis" {
    count = 1

    network {
      mode = "bridge"
    }

    service {
      name = "redis"
      tags = ["global", "cache"]
      port = "6379"

      connect {
	sidecar_service {}
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:6"
      }
    }
  }
}
