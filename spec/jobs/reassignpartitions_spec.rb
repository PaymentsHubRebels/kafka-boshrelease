require 'rspec'
require 'json'
require 'yaml' # todo fix bosh-template
require 'bosh/template/test'

describe 'reassignpartitions job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('reassignpartitions') }

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

    def produce_kafka_links(number = 1, topics = [])
      Bosh::Template::Test::Link.new(
        name: 'kafka',
        instances: (1..number).map { |n| Bosh::Template::Test::LinkInstance.new() },
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

    describe "with bad topics" do
      let(:kafka_link) { produce_kafka_links }
      let(:links) { [ zookeeper_link, kafka_link ]}

      let(:property_with_wrong_type) {
        {
          "topics" => "3"
        }
      }
      let(:nil_property) {
        {
          "topics" => nil
        }
      }
      it "reacts accordingly" do
        expect { template.render(property_with_wrong_type, consumes: links) }.to raise_error(Bosh::Template::EvaluationContext::InvalidTopicsTypeError)
        expect { template.render(nil_property, consumes: links) }.not_to raise_error
      end
      it "does not produce output" do
        expect(template.render(nil_property, consumes: links)).not_to include("# processing topic")
      end
    end

    describe "with topics" do
      let(:single_kafka_link) { produce_kafka_links }
      let(:multiple_kafka_link) { produce_kafka_links(3) }
      let(:single_kafka_links) { [ zookeeper_link, single_kafka_link ]}
      let(:multiple_kafka_links) { [ zookeeper_link, multiple_kafka_link ]}

      let(:one_topic) {
        {
          "topics" => [
            {
              "name" => "topic1",
              "partitions" => 3,
              "replication_factor" => 3
            }
          ]
        }
      }
      let(:multiple_topics) {
        {
          "topics" => [
            {
              "name"=> "topic1",
              "partitions"=> 3,
              "replication_factor"=> 3
            },
            {
              "name"=> "topic2",
              "partitions"=> 3,
              "replication_factor"=> 2
            }
          ]
        }
      }
      it "render properly" do
        expect { template.render(one_topic, consumes: multiple_kafka_links) }.not_to raise_error
        expect { template.render(multiple_topics, consumes: multiple_kafka_links) }.not_to raise_error
        expect(template.render(one_topic, consumes: multiple_kafka_links)).to include("# processing topic topic1")
        expect(template.render(multiple_topics, consumes: multiple_kafka_links)).to include("# processing topic topic1")
        expect(template.render(multiple_topics, consumes: multiple_kafka_links)).to include("# processing topic topic2")
      end

      it "does not render if brokers are few" do
        expect { template.render(one_topic, consumes: single_kafka_links) }.to raise_error(Bosh::Template::EvaluationContext::ReplicationFactorTooBigError)
        expect { template.render(multiple_topics, consumes: single_kafka_links) }.to raise_error(Bosh::Template::EvaluationContext::ReplicationFactorTooBigError)
      end
    end
  end
end