require 'spec_helper'

describe BlueFactory::UserInfo do
  context 'with a correct bearer token' do
    let(:header) { 'Bearer abcdefghijklmnop' }

    it 'should extract the bearer token' do
      user = BlueFactory::UserInfo.new(header)
      user.token.should == 'abcdefghijklmnop'
    end

    it 'should decode the raw DID from the token payload' do
      payload = Base64.encode64(JSON.generate({ iss: 'did:plc:44ybard66vv44zksje25o7dz' }))
      token = "header.#{payload}.signature"

      user = BlueFactory::UserInfo.new("Bearer #{token}")
      user.raw_did.should == 'did:plc:44ybard66vv44zksje25o7dz'
    end
  end

  context 'when the header is missing' do
    let(:header) { nil }

    describe '#token' do
      it 'should return nil' do
        user = BlueFactory::UserInfo.new(header)
        user.token.should be nil
      end
    end

    describe '#raw_did' do
      it 'should return nil' do
        user = BlueFactory::UserInfo.new(header)
        user.raw_did.should be nil        
      end
    end
  end

  context 'when the header is blank' do
    let(:header) { ' ' }

    describe '#token' do
      it 'should return nil' do
        user = BlueFactory::UserInfo.new(header)
        user.token.should be nil
      end
    end

    describe '#raw_did' do
      it 'should return nil' do
        user = BlueFactory::UserInfo.new(header)
        user.raw_did.should be nil        
      end
    end
  end

  context 'when the header is not a bearer token' do
    let(:header) { 'Basic wtf' }

    describe '#token' do
      it 'should raise error' do
        user = BlueFactory::UserInfo.new(header)

        expect { user.token }.to raise_error(BlueFactory::AuthorizationError)
      end
    end

    describe '#raw_did' do
      it 'should raise error' do
        user = BlueFactory::UserInfo.new(header)

        expect { user.raw_did }.to raise_error(BlueFactory::AuthorizationError)
      end
    end
  end

  context 'when the bearer token has too few parts' do
    let(:header) { 'Bearer bad.token' }

    describe '#token' do
      it 'should extract the token' do
        user = BlueFactory::UserInfo.new(header)
        user.token.should == 'bad.token'
      end
    end

    describe '#raw_did' do
      it 'should raise error' do
        user = BlueFactory::UserInfo.new(header)

        expect { user.raw_did }.to raise_error(BlueFactory::AuthorizationError)
      end
    end
  end

  context 'when the bearer token has too many parts' do
    let(:header) { 'Bearer such.long.token.much.wow' }

    describe '#token' do
      it 'should extract the token' do
        user = BlueFactory::UserInfo.new(header)
        user.token.should == 'such.long.token.much.wow'
      end
    end

    describe '#raw_did' do
      it 'should raise error' do
        user = BlueFactory::UserInfo.new(header)

        expect { user.raw_did }.to raise_error(BlueFactory::AuthorizationError)
      end
    end
  end

  context 'when the bearer token contains invalid Base64' do
    let(:header) { 'Bearer good.token.length' }

    describe '#token' do
      it 'should extract the token' do
        user = BlueFactory::UserInfo.new(header)
        user.token.should == 'good.token.length'
      end
    end

    describe '#raw_did' do
      it 'should raise error' do
        user = BlueFactory::UserInfo.new(header)

        expect { user.raw_did }.to raise_error(BlueFactory::AuthorizationError)
      end
    end
  end

  context 'when the bearer token contains invalid JSON' do
    let(:payload) { Base64.encode64('nevergonnagiveyouup') }
    let(:token) { "header.#{payload}.signature" }
    let(:header) { "Bearer #{token}" }

    describe '#token' do
      it 'should extract the token' do
        user = BlueFactory::UserInfo.new(header)
        user.token.should == token
      end
    end

    describe '#raw_did' do
      it 'should raise error' do
        user = BlueFactory::UserInfo.new(header)

        expect { user.raw_did }.to raise_error(BlueFactory::AuthorizationError)
      end
    end
  end

  context 'when the bearer token contains no :iss' do
    let(:payload) { Base64.encode64(JSON.generate({ exp: 111, wow: 10 })) }
    let(:token) { "header.#{payload}.signature" }
    let(:header) { "Bearer #{token}" }

    describe '#token' do
      it 'should extract the token' do
        user = BlueFactory::UserInfo.new(header)
        user.token.should == token
      end
    end

    describe '#raw_did' do
      it 'should raise error' do
        user = BlueFactory::UserInfo.new(header)

        expect { user.raw_did }.to raise_error(BlueFactory::AuthorizationError)
      end
    end
  end
end
