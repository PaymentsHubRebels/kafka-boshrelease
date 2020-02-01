require 'rspec'
require 'json'
require 'yaml' # todo fix bosh-template
require 'bosh/template/test'

describe 'kafka job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('kafka') }

  describe "server.properties template" do
    let(:template) { job.template("config/server.properties") }
    let(:zookeeper_link) {
      Bosh::Template::Test::Link.new(
        name: 'zookeeper',
        instances: [Bosh::Template::Test::LinkInstance.new()],
        properties: {
          "client_port" => 1
        }
      )
    }

    let(:links) {
      [zookeeper_link]
    }
    
    describe "with default manifest values" do
      it "renders properly" do
        expect { template.render({}, consumes: links) }.not_to raise_error
      end
    end

    describe "using rack awareness" do
      let(:manifest) {
        {
          "rack_id" => "az"
        }
      }
      it "renders properly" do
        expect { template.render(manifest, consumes: links) }.not_to raise_error
      end

      it "sets the az to the one the instance uses" do
        expect(template.render(manifest, consumes: links)).to include("broker.rack=az1")
      end
    end

    describe "using indexing and spacing" do
      let(:manifest) {
        {  
          "starting_index" => "3",
          "index_spacing" => "2"
        }
      }

      let(:instance_2) { Bosh::Template::Test::InstanceSpec.new(name:'kafka', az: 'az3', bootstrap: false, index: 2) }

      it "renders properly" do
        expect { template.render(manifest, consumes: links) }.not_to raise_error
      end

      it "sets broker id based on starting index provided" do
        expect(template.render(manifest, consumes: links)).to include("broker.id=3")
      end

      it "sets broker id for third instance based on starting index provided" do
        expect(template.render(manifest, spec: instance_2, consumes: links)).to include("broker.id=7")
      end
    end
  end
end