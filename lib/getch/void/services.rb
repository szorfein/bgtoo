# frozen_string_literal: true

module Getch
  module Void
    class Services
      def initialize
        x
      end

      protected

      def x
        Config::Iwd.new
        Config::Dhcp.new
      end
    end
  end
end
