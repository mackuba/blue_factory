require 'spec_helper'
require 'rack'

describe BlueFactory::RequestContext do
  let(:env) {{
    'HTTP_AUTHORIZATION' => 'Bearer qwertyuiop'
  }}

  let(:request) { Rack::Request.new(env) }

  describe '#request' do
    it 'should return the underlying request' do
      ctx = BlueFactory::RequestContext.new(request)
      ctx.request.should == request
    end
  end

  describe '#env' do
    it "should return the request's environment" do
      ctx = BlueFactory::RequestContext.new(request)
      ctx.env.should == env
    end
  end

  context 'if env includes HTTP_AUTHORIZATION' do
    describe '#user' do
      it 'should return a UserInfo with parsed token' do
        ctx = BlueFactory::RequestContext.new(request)

        ctx.user.should be_a(BlueFactory::UserInfo)
        ctx.user.token.should == 'qwertyuiop'
      end
    end

    describe '#has_auth?' do
      it 'should return true' do
        ctx = BlueFactory::RequestContext.new(request)
        ctx.has_auth?.should == true
      end
    end
  end

  context 'if env does not include HTTP_AUTHORIZATION' do
    before do
      env.delete('HTTP_AUTHORIZATION')
    end

    describe '#user' do
      it 'should return a UserInfo with no token' do
        ctx = BlueFactory::RequestContext.new(request)

        ctx.user.should be_a(BlueFactory::UserInfo)
        ctx.user.token.should be_nil
      end
    end

    describe '#has_auth?' do
      it 'should return false' do
        ctx = BlueFactory::RequestContext.new(request)
        ctx.has_auth?.should == false
      end
    end
  end
end
