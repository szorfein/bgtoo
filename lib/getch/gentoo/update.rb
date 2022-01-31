# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    class Update
      include NiTo

      def initialize
        @log = Log.new
        x
      end

      protected

      def x
        sync
        update
      end

      private

      def sync
        gentoo_conf = "#{OPTIONS[:mountpoint]}/etc/portage/repos.conf/gentoo.conf"
        @log.info "Synchronize index, please waiting...\n"
        Getch::Emerge.new('emaint sync --auto').run!
        sed gentoo_conf, /^sync-type/, 'sync-type = rsync'
      end

      def update
        cmd = 'emerge --update --deep --newuse @world'
        Getch::Emerge.new(cmd).run!
      end
    end
  end
end
