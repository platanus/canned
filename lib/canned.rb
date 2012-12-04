require "canned/version"

require "canned/errors"
require "canned/test_context"
require "canned/definition"
require "canned/controller_ext"

# Extend action controller
if defined? ActionController::Base
  ActionController::Base.class_eval do
    include Canned::ControllerExt
  end
end