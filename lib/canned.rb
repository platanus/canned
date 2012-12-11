require "canned/version"

require "canned/errors"
require "canned/controller_ext"

# Extend action controller
if defined? ActionController::Base
  ActionController::Base.class_eval do
    include Canned::ControllerExt
  end
end