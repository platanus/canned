module Canned
  class Error < StandardError; end
  class SetupError < Error; end
  class AuthError < Error; end
  class ForbiddenError < AuthError; end
end
