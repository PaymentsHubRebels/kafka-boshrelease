require 'rspec'
require 'json'
require 'yaml' # todo fix bosh-template
require 'bosh/template/test'

describe 'generatetopics job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('generatetopics') }

  describe "run script" do
    let(:template) { job.template("bin/run") }
    let(:zookeeper_link) {
      Bosh::Template::Test::Link.new(
        name: 'zookeeper',
        instances: [Bosh::Template::Test::LinkInstance.new()],
        properties: {
          "client_port" => 1
        }
      )
    }

    def produce_kafka_links(topics = [])
      Bosh::Template::Test::Link.new(
        name: 'kafka',
        instances: [Bosh::Template::Test::LinkInstance.new()],
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
          "listen_port" => 1
        }
      )
    end

    describe "with no topics" do
      let(:kafka_link) { produce_kafka_links }
      let(:links) { [ zookeeper_link, kafka_link ]}

      it "renders properly" do
        expect { template.render({}, consumes: links) }.not_to raise_error
      end  
    end

    describe "with topics" do
      let(:kafka_link) { produce_kafka_links([{
        "replication_factor" => 3,
        "partition" => 2,
        "name" => "aTopic"
      }]) }
      let(:links) { [ zookeeper_link, kafka_link ]}

      it "renders properly" do
        kafka_topics_parts = [
          "kafka-topics.sh", 
          "--replication-factor 3",
          "--partitions 1"
        ]
        rendered_template = template.render({}, consumes: links)
        kafka_topics_parts.each do |part|
          expect(rendered_template).to include(part)
        end
      end
    end
  end
end