# In the Python library, this file is named `core.py`. Here it's
# `push.rb` in keeping with the Ruby convention of naming the
# file based on the class it contains.
module Urbanairship
  module Push

    # A push notification.
    class Push
      attr_writer :audience, :notification, :options, :device_types, :message

      def initialize(airship)
        @airship = airship
      end
    end

  end
end