# frozen_string_literal: true

module Getch
  module Void
    # config after installing the rootfs
    class PostConfig
      def initialize
        x
      end

      protected

      def x
        Getch::Config::Locale.new
        Getch::Config::Keymap.new
        Getch::Config::TimeZone.new
      end
    end
  end
end
