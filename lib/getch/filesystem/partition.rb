module Getch
  module FileSystem
    class Partition
      def initialize
        @log = Getch::Log.new
      end

      def gpt(dev)
        return if ! dev
        part = dev.match(/[0-9]/)
        exec("sgdisk -n#{part}:1MiB:+1MiB -t#{part}:EF02 #{dev}")
      end

      def boot(dev)
        return if ! dev
        part = dev.match(/[0-9]/)
        exec("sgdisk -n#{part}:0:+128MiB -t#{part}:8300 #{dev}")
      end

      def efi(dev)
        return if ! dev
        part = dev.match(/[0-9]/)
        exec("sgdisk -n#{part}:1M:+260M -t#{part}:EF00 #{dev}")
      end

      def swap(dev)
        return if ! dev
        part = dev.match(/[0-9]/)
        if DEFAULT_OPTIONS[:cache_disk]
          exec("sgdisk -n#{part}:0:0 -t#{part}:8200 #{dev}")
        else
          mem=`awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
          exec("sgdisk -n#{part}:0:+#{mem} -t#{part}:8200 #{dev}")
        end
      end

      def root(dev, code)
        return if ! dev
        part = dev.match(/[0-9]/)
        # Reserve 18G for the system if you need a home partition
        if DEFAULT_OPTIONS[:username]
          exec("sgdisk -n#{part}:0:+18G -t#{part}:#{code} #{dev}")
        else
          exec("sgdisk -n#{part}:0:0 -t#{part}:#{code} #{dev}")
        end
      end

      def home(dev, code)
        return if ! dev
        part = dev.match(/[0-9]/)
        if DEFAULT_OPTIONS[:home_disk]
          exec("sgdisk -n#{part}:0:0 -t#{part}:#{code} #{dev}")
        end
      end

      private

      def exec(cmd)
        @log.debug "Partition disk with #{cmd}"
        if DEFAULT_OPTIONS[:encrypt]
          Helpers::sys(cmd)
        else
          Getch::Command.new(cmd).run!
        end
      end
    end
  end
end
