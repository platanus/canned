require 'spec_helper'

describe Canned do

  describe "TestProfiles.validate" do

    context 'when using profile with a context' do

      let(:definition) do
        class TestProfiles
          include Canned::Definition

          profile :profile do
            context { the(:user) }
            allow 'rute1', upon { asks_with_same_id(:app_id) }
            allow 'rute2', upon { asks_for(:test) }
            forbid 'rute3', upon { not is(:is_admin) }
          end
        end
        TestProfiles
      end

      context 'and a matching context' do
        let(:context) do
          dummy(
            action_name: 'test',
            actors: { user: dummy(app_id: 10, is_admin: false) },
            resources: {},
            params: { app_id: "10" }
          )
        end

        it "is allowed if asks for same id" do
          definition.validate(context, :profile, 'rute1').should == :allowed
        end

        it "is allowed if asks for same action" do
          definition.validate(context, :profile, 'rute2').should == :allowed
        end

        it "is forbidden if 'is' expression returns true" do
          definition.validate(context, :profile, 'rute3').should == :forbidden
        end
      end
    end

    context 'when using simple profile' do

      let(:definition) do
        class TestProfiles
          include Canned::Definition

          profile :profile do
            allow 'action1', upon(:user) { asks_with_same_id(:app_id) }
            allow 'action2', upon(:user) { belongs_to(:app, as: :app) }
            allow 'action3', upon(:user) { asks_with_same(:app_id) }
          end
        end
        TestProfiles
      end

      context 'and an allowed context with actor and resource' do
        let(:context) do
          dummy(
            action_name: 'test',
            actors: { user: dummy(app_id: 10, is_admin: true) },
            resources: { app: dummy(id: 10) },
            params: { app_id: "10" }
          )
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
          dummy(
            action_name: 'test',
            actors: { user: dummy(app_id: 10, is_admin: true) },
            resources: {},
            params: { app_id: "11" }
          )
        end

        it "is not allowed" do
          definition.validate(context, :profile, 'action1').should == :default
        end
      end

      context 'and does not belong to resource' do
        let(:context) do
          dummy(
            action_name: 'test',
            actors: { user: dummy(app_id: 10, is_admin: true) },
            resources: { app: dummy(id: 11) },
            params: {}
          )
        end

        it "is not allowed" do
          definition.validate(context, :profile, 'action2').should == :default
        end
      end
    end
  end
end