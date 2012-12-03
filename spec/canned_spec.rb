require 'spec_helper'

describe Canned do

  ## Dummy context used for the tests
  class DummyCtx

    attr_reader :actors
    attr_reader :resources
    attr_reader :params

    def initialize(_actors, _resources, _params)
      @actors = _actors
      @resources = _resources
      @params = _params
    end
  end

  describe "TestProfiles.validate" do

    context 'when using profile with global actor' do

      let(:definition) do
        class TestProfiles
          include Canned::Definition

          profile :profile, upon: :user do
            allow 'rute1#action1', upon { asks_for_same_id(:app_id) }
          end
        end
        TestProfiles
      end

      context 'and an allowed context' do
        let(:context) do
          Canned::TestContext.new DummyCtx.new({ user: dummy(app_id: 10) }, {}, { app_id: "10" })
        end

        it "is allowed if asks for same id" do
          definition.validate(context, :profile, 'rute1#action1').should == :allowed
        end
      end
    end

    context 'when using simple profile' do

      let(:definition) do
        class TestProfiles
          include Canned::Definition

          profile :profile, upon: :user do
            allow 'action1', upon(:user) { asks_for_same_id(:app_id) }
            allow 'action2', upon(:user) { belongs_to(app, as: :app) }
            allow 'action3', upon(:user) { asks_for_same(:app_id) }
          end
        end
        TestProfiles
      end

      context 'and an allowed context with actor and resource' do
        let(:context) do
          Canned::TestContext.new DummyCtx.new({ user: dummy(app_id: 10, is_admin: true) }, { app: dummy(id: 10) }, { app_id: "10" })
        end

        it "is allowed if calls asks_for_same_id" do
          definition.validate(context, :profile, 'action1').should == :allowed
        end

        it "is allowed if belongs_to resource" do
          definition.validate(context, :profile, 'action2').should == :allowed
        end

        it "is not allowed if asks_for_same instead of asks_same_id" do
          definition.validate(context, :profile, 'action3').should == :default
        end
      end

      context 'and does not ask for same id' do
        let(:context) do
          Canned::TestContext.new DummyCtx.new({ user: dummy(app_id: 10, is_admin: true) }, {}, { app_id: "11" })
        end

        it "is not allowed" do
          definition.validate(context, :profile, 'action1').should == :default
        end
      end

      context 'and does not belong to resource' do
        let(:context) do
          Canned::TestContext.new DummyCtx.new({ user: dummy(app_id: 10, is_admin: true) }, { app: dummy(id: 11) }, {})
        end

        it "is not allowed" do
          definition.validate(context, :profile, 'action2').should == :default
        end
      end
    end
  end
end