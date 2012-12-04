require 'spec_helper'

describe Canned::ControllerExt do

  let(:controller_class) do
    controller_class = Class.new
    controller_class.send(:include, Canned::ControllerExt)
    controller_class
  end

  let(:controller) do
    controller = controller_class.new
    controller.stub(:params) { { app_id: 10 } }
    controller.stub(:controller_name) { 'controller' }
    controller.stub(:action_name) { 'action' }
    controller.stub(:good_user) { dummy(app_id: 10, is_admin: true) }
    controller.stub(:bad_user) { dummy(app_id: 11) }
    controller
  end

  let(:definition) do
    class TestProfiles
      include Canned::Definition

      profile :profile, upon: :user do
        allow 'controller#action', upon(:user) { asks_for_same_id(:app_id) }
      end

      profile :profile2, upon: :user do
        allow 'controller#action', upon(:user) { belongs_to(resource, as: :app) }
      end
    end
    TestProfiles
  end

  describe ".is_restricted?" do
    context 'when action is restricted' do
      it { controller.is_restricted?.should be_true }
    end
    context 'when action is not restricted' do
      before { controller_class.unrestricted :action }
      it { controller.is_restricted?.should be_false }
    end
  end

  describe ".perform_resource_loading" do

    context 'when registering resource for another action' do
      let(:proxy) do
        controller_class.register_resource(:resource, only: [:other]) { HashObj.new(id: 10) }
        controller.perform_resource_loading
      end
      it { proxy.resources.has_key?(:resource).should be_false }
    end

    context 'when registering resource except for this action' do
      let(:proxy) do
        controller_class.register_resource(:resource, except: [:action]) { HashObj.new(id: 10) }
        controller.perform_resource_loading
      end
      it { proxy.resources.has_key?(:resource).should be_false }
    end
  end

  describe ".perform_access_authorization" do

    context 'when registering and testing a valid actor' do
      let(:result) do
        controller_class.register_actor :good_user, as: :user
        controller.perform_access_authorization(definition, [:profile])
      end
      it { result.should be_true }
    end

    context 'when registering and testing a valid actor and resource' do
      let(:result) do
        controller_class.register_actor :good_user, as: :user
        controller_class.register_resource(:resource) { HashObj.new(id: 10) }
        controller.perform_access_authorization(definition, [:profile2])
      end
      it { result.should be_true }
    end
  end
end