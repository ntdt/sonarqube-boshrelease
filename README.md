# sonarqube-boshrelease
This release is designed to use postgres and haproxy

## Releases for ssl and database
* http://bosh.io/d/github.com/cloudfoundry/postgres-release?v=18
* http://bosh.io/d/github.com/cloudfoundry-community/haproxy-boshrelease?v=8.3.0
* You can push nist-data-mirror-boshrelease on the same deployment

## Release usage
* This release is in dev, so to use it follow this step
```shell
git clone https://github.com/camillemahaut/sonarqube-boshrelease.git
cd sonarqube-boshrelease
./scripts/build-release.sh
```
depends on your bosh cli version
```shell
bosh -e $env upload-release
```
* then deploy with your manifest

## sonarqube property example
```yaml manifest
 sonarqube:
  jdbc_url: jdbc:postgresql://localhost:5432/sonarqube
  jdbc_user: user
  jdbc_password: password
  postgres_port: 5432
  web_port: 9000
  web_host: 127.0.0.1
  web_context: /
```
## postgresSQL property example
```yaml manifest
 databases:
  databases:
  - citext: true
    name: sonarqube
    tag: sonarqube
  port: 5432
  roles:
  - name: user
    password: password
    tag: admin
    permissions:
    - CONNECTION LIMIT 10
```

## haproxy property example
```yaml manifest
 ha_proxy:
  ssl_pem: |
    -----BEGIN CERTIFICATE-----
    MIIDlzCCAyour certificate
    -----END CERTIFICATE-----
    -----BEGIN PRIVATE KEY-----
    MIIEvAI private key  y+yAzqg5QioHxCok3+KAog==
    -----END PRIVATE KEY-----
 routed_backend_servers:
   /sonar:
    servers: [127.0.0.1] 
    port: 9000
   /nistmirror:
    servers: [127.0.0.1] 
    port: 8081
  https_redirect_all: true

```



