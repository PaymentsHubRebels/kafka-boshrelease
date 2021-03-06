# BOSH release for kafka

This BOSH release and deployment manifest deploy a cluster of kafka.

## Usage

This repository includes base manifests and operator files. They can be used for initial deployments and subsequently used for updating your deployments:

```plain
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=kafka
git clone https://github.com/cloudfoundry-community/kafka-boshrelease.git
bosh deploy kafka-boshrelease/manifests/kafka.yml

bosh run-errand sanity-test
```

If your BOSH does not have Credhub/Config Server, then remember `--vars-store` to allow generation of passwords and certificates.

### Topics

> Topics used to be created while deploying. That has shown some issues in subsequent deployments on heavy loaded deployments where syncronisation is suffering. Usage of errand `generatetopics` is required in order to apply all topics provided in deployment.

You can pre-define some simple topics using an operator script `./manifests/operators/simple-topics.sh`. Th

```plain
bosh deploy kafka-boshrelease/manifests/kafka.yml \
  -o <(kafka-boshrelease/manifests/operators/simple-topics.sh test1 test2)
bosh run-errand generatetopics
```

### Enable SASL/SCRAM and TLS

You can enable [SASL/SCRAM](https://kafka.apache.org/documentation/#security_sasl_config) using `./manifests/operators/add-jaas.yml`. 
`SASL_PLAINTEXT` and `SASL_TLS` are supported as a security protocol.

```
bosh deploy kafka-boshrelease/manifests/kafka.yml \
  -o kafka-boshrelease/manifests/operators/enable-jaas.yml
```

You can find `admin`'s password by `credhub get -n /(director name)/kafka/jaas-admin-password`.

If you want to use `SASL_TLS`, use `./manifests/operators/add-tls.yml` as well.

```

bosh deploy kafka-boshrelease/manifests/kafka.yml \
  -o kafka-boshrelease/manifests/operators/enable-jaas.yml \
  -o kafka-boshrelease/manifests/operators/enable-tls.yml \
  -v kafka-external-host=${your-kafka-hostname-or-static-ip} \
```

`kafka-boshrelease/manifests/operators/enable-tls.yml` is supposed to be used for single kafka instance group.
To scale out the kafka cluster, change `advertised.listener` property and `kafka-tls` variable.

You can use Let's Encrypt as follows:

```
bosh deploy kafka-boshrelease/manifests/kafka.yml \
  -o kafka-boshrelease/manifests/operators/enable-jaas.yml \
  -o kafka-boshrelease/manifests/operators/enable-tls.yml \
  --var-file kafka-tls.certificate=/etc/letsencrypt/live/your-kafka.example.com/fullchain.pem \
  --var-file kafka-tls.private_key=/etc/letsencrypt/live/your-kafka.example.com/privkey.pem \
  --var-file kafka-ca.certificate=<(curl https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt) \
  -v kafka-external-host=your-kafka.example.com
```



### Kafka Manager

![kafka-manager](https://github.com/cloudfoundry-community/kafka-boshrelease/raw/master/doc/kafka-manager.png)

The [Yahoo Kafka Manager](https://github.com/yahoo/kafka-manager) UI is installed on each Kafka node. You can access it via port 8080. To access via http://localhost:8080, open a tunnel:

```plain
bosh ssh kafka-manager/0 -- -L 8080:127.0.0.1:8080
```

Kafka Manager requires basic auth credentials. The default `username` is `admin`, and the `password` is the `((kafka-manager-password))` value from either Credhub/Config Server, or your `--vars-store creds.yml` file.

### Rack awareness

Following the documentation on [rack awareness](http://kafka.apache.org/documentation/#basic_ops_racks) by setting the `rack_id` property to `az` the rack_id for each instance becomes the zone it instanciates.

### Broker ID spacing

Broker ids are based on spec.id of each `kafka` instance. If custom numbering is required providing the `statring_index` and the `index_spacing` properties will change the default behaviour.

### Update

When new versions of `kafka-boshrelease` are released the `manifests/kafka.yml` file will be updated. This means you can easily `git pull` and `bosh deploy` to upgrade.

```plain
export BOSH_ENVIRONMENT=<bosh-alias>
export BOSH_DEPLOYMENT=kafka
cd kafka-boshrelease
git pull
cd -
bosh deploy kafka-boshrelease/manifests/kafka.yml
```

### Development

To iterate on this BOSH release, use the `create.yml` manifest when you deploy:

```plain
bosh deploy manifests/kafka.yml -o manifests/operators/create.yml
```

#### Testing

`generatetopics` errand has some basic testing.

In order to run testing `ruby` is required.

```
gem install bundler
bundle install
bundle exec rspec
```

In order to interactively run tests when developing:
```
bundle exec guard
```
