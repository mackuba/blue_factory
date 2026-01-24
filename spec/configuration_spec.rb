require 'spec_helper'

describe BlueFactory do
  before do
    BlueFactory.instance_variable_get("@properties").each do |prop|
      if BlueFactory.instance_variable_get("@#{prop}")
        BlueFactory.remove_instance_variable("@#{prop}")
      end
    end

    if BlueFactory.instance_variable_get("@interactions_handler")
      BlueFactory.remove_instance_variable("@interactions_handler")
    end
  end

  describe '.set' do
    it 'should set hostname' do
      BlueFactory.set :hostname, 'foo.example.com'
      BlueFactory.hostname.should == 'foo.example.com'
    end

    it 'should set publisher_did' do
      BlueFactory.set :publisher_did, 'did:plc:sdgfncjshfgnscjd'
      BlueFactory.publisher_did.should == 'did:plc:sdgfncjshfgnscjd'
    end

    context 'with string keys' do
      it 'should work the same' do
        BlueFactory.set 'hostname', 'europa.eu'
        BlueFactory.hostname.should == 'europa.eu'

        BlueFactory.set 'publisher_did', 'did:plc:asdasdasdasd'
        BlueFactory.publisher_did.should == 'did:plc:asdasdasdasd'
      end
    end

    context 'with an unknown property' do
      it 'should raise an error' do
        expect { BlueFactory.set :foobar, 'value' }.to raise_error(NoMethodError)
      end
    end
  end

  describe '.service_did' do
    it 'should return did:web based on the configured hostname' do
      BlueFactory.set :hostname, 'myserver.com'
      BlueFactory.service_did.should == 'did:web:myserver.com'
    end

    it "should raise an error if domain isn't configured" do
      expect { BlueFactory.service_did }.to raise_error(BlueFactory::ConfigurationError)
    end
  end

  describe '.on_interactions' do
    it 'should set an interaction handler' do
      called = nil
      int = BlueFactory::Interaction.new({})

      BlueFactory.on_interactions do |x|
        called = x
      end

      BlueFactory.interactions_handler.should be_a(Proc)

      BlueFactory.interactions_handler.call(int)
      called.should == int
    end
  end

  describe '.interactions_handler=' do
    it 'should set an interaction handler' do
      called = nil
      int = BlueFactory::Interaction.new({})

      BlueFactory.interactions_handler = proc { |x| called = x }
      BlueFactory.interactions_handler.should be_a(Proc)

      BlueFactory.interactions_handler.call(int)
      called.should == int
    end
  end
end
