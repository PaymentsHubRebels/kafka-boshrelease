require 'rspec'
require 'json'
require 'yaml' # todo fix bosh-template
require 'bosh/template/test'

describe 'sanitytest job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('sanitytest') }

  describe "config/kafka_discovery/cluster.yaml template" do
    let(:template) { job.template("config/kafka_discovery/cluster.yaml") }
    let(:zookeeper_link) {
      Bosh::Template::Test::Link.new(
        name: 'zookeeper',
        instances: [Bosh::Template::Test::LinkInstance.new(name: 'zook-1',
        index: 0,
        az: 'az4',
        address: 'zook-1.example.com',
        bootstrap: true),
        Bosh::Template::Test::LinkInstance.new(name: 'zook-2',
        index: 1,
        az: 'az4',
        address: 'zook-2.example.com',
        bootstrap: false)],
        properties: {
          "client_port" => 1
        }
      )
    }

    def produce_kafka_links(topics = [])
      Bosh::Template::Test::Link.new(
        name: 'kafka',
        instances: [Bosh::Template::Test::LinkInstance.new(name: 'kafka-1',
        index: 0,
        az: 'az4',
        address: 'kafka-1.example.com',
        bootstrap: true),
        Bosh::Template::Test::LinkInstance.new(name: 'kafka-2',
        index: 1,
        az: 'az4',
        address: 'kafka-2.example.com',
        bootstrap: false)],
        properties: {
          "tls" => {
            "ca_certs" => "",
            "certificate" => ""  
          },
          "keystore_password" => "",
          "enable_sasl_scram" => "",
          "jaas_admin" => {
            "username" => "",
            "password" => ""
          },
          "topics" => topics,
          "listen_port" => 1234
        }
      )
    end

    let(:kafka_link) { produce_kafka_links([{
      "replication_factor" => 3,
      "partition" => 2,
      "name" => "aTopic"
    }]) }
    let(:links) { [ zookeeper_link, kafka_link ]}
    
    describe "with default manifest values" do
      it "renders properly" do
        expect { template.render({}, consumes: links) }.not_to raise_error
      end
       

       it "contains kafka brokers instances" do
        kafkahosts = ['kafka-1.example.com', 'kafka-2.example.com']
       
        renderedTemplate = template.render({}, consumes: links)
        kafkahosts.each do |khost|
          expect(renderedTemplate).to include(khost)
        end
      end

      it "contains zookeeper instances" do
        zookeeperhosts = ['zook-1.example.com', 'zook-2.example.com']
        
        renderedTemplate = template.render({}, consumes: links)
        zookeeperhosts.each do |zhost|
          expect(renderedTemplate).to include(zhost)
        end
      end
    end
  end
end