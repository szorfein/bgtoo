# frozen_string_literal: true

require 'open-uri'
require 'open3'
require 'fileutils'
require 'nito'

module Getch
  module Helpers
    def self.efi?
      Dir.exist? '/sys/firmware/efi/efivars'
    end

    def self.systemd?
      Dir.exist? "#{OPTIONS[:mountpoint]}/etc/systemd"
    end

    def self.openrc?
      File.exist? "#{OPTIONS[:mountpoint]}/etc/conf.d/keymaps"
    end

    def self.get_file_online(url, dest)
      URI.open(url) do |l|
        File.open(dest, "wb") { |f| f.write(l.read) }
      end
    rescue Net::OpenTimeout => e
      abort "DNS error #{e}"
    end

    def self.exec_or_die(cmd)
      _, stderr, status = Open3.capture3(cmd)
      unless status.success?
        abort "Problem running #{cmd}, stderr was:\n#{stderr}"
      end
    end

    def self.sys(cmd)
      system(cmd)
      $?.success? || abort("Error with #{cmd}")
    end

    def self.partuuid(dev)
      `lsblk -o PARTUUID #{dev}`.match(/\w+-\w+-\w+-\w+-\w+/)
    end

    def self.uuid(dev)
      Dir.glob('/dev/disk/by-uuid/*').each do |f|
        if File.readlink(f).match(/#{dev}/)
          return f.delete_prefix('/dev/disk/by-uuid/')
        end
      end
      Log.new.fatal("UUID on #{dev} is no found")
    end

    def self.get_dm(name)
      Dir.glob('/dev/mapper/*').each do |f|
        if f =~ /#{name}/ && f != '/dev/mapper/control'
          return File.readlink(f).tr('../', '')
        end
      end
      nil
    end

    # Used by ZFS for the pool creation
    def self.get_id(dev)
      Dir.glob('/dev/disk/by-id/*').each do |f|
        if File.readlink(f).match(/#{dev}/)
          return f.delete_prefix('/dev/disk/by-id/')
        end
      end
      Log.new.fatal("ID on #{dev} is no found")
    end

    # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base
    def self.mount_all
      dest = OPTIONS[:mountpoint]
      NiTo.mount '--types proc /proc', "#{dest}/proc"
      ['dev', 'sys', 'run'].each do |d|
        NiTo.mount '--rbind', "/#{d}", "#{dest}/#{d}"
        NiTo.mount '--make-rslave', "#{dest}/#{d}"
      end
    end

    def self.get_memory
      mem = nil
      File.open('/proc/meminfo').each do |l|
        t = l.split(' ') if l =~ /memtotal/i
        t && mem = t[1]
      end
      mem || Log.new.fatal('get_memory - failed to get memory')

      mem += 'K'
    end

    # get the sector size of a disk
    def self.get_bs(path)
      cmd = Getch::Command.new('blockdev', '--getpbsz', path)
      cmd.res
    end

    module Void
      def command(args)
        print " => Exec: #{args}..."
        cmd = "chroot #{Getch::MOUNTPOINT} /bin/bash -c \"#{args}\""
        _, stderr, status = Open3.capture3(cmd)
        if status.success?
          puts "\s[OK]"
          return
        end
        raise "\n[-] Fail cmd #{args} - #{stderr}."
      end

      def command_output(args)
        print " => Exec: #{args}..."
        cmd = "chroot #{Getch::MOUNTPOINT} /bin/bash -c \"#{args}\""
        Open3.popen2e(cmd) do |_, stdout_err, wait_thr|
          puts
          stdout_err.each { |l| puts l }

          exit_status = wait_thr.value
          unless exit_status.success?
            raise "\n[-] Fail cmd #{args} - #{stdout_err}."
          end
        end
      end

      def add_line(file, line)
        raise "No file #{file} found !" unless File.exist? file

        File.write(file, "#{line}\n", mode: 'a')
      end

      def search(file, text)
        File.open(file).each do |line|
          return true if line.match(/#{text}/)
        end
        false
      end

      # Used only when need password
      def chroot(cmd)
        unless system('chroot', Getch::MOUNTPOINT, '/bin/bash', '-c', cmd)
          raise "[-] Error with: #{cmd}"
        end
      end

      def s_uuid(dev)
        device = dev.delete_prefix('/dev/')
        Dir.glob('/dev/disk/by-partuuid/*').each do |f|
          link = File.readlink(f)
          return f.delete_prefix('/dev/disk/by-partuuid/') if link.match(/#{device}$/)
        end
      end

      def line_fstab(dev, rest)
        conf = "#{Getch::MOUNTPOINT}/etc/fstab"
        device = s_uuid(dev)
        raise "No partuuid for #{dev} #{device}" unless device
        raise "Bad partuuid for #{dev} #{device}" if device.kind_of? Array

        add_line(conf, "PARTUUID=#{device} #{rest}")
      end

      def grub_cmdline(*args)
        conf = "#{Getch::MOUNTPOINT}/etc/default/grub"
        list = args.join(' ')
        secs = "GRUB_CMDLINE_LINUX=\"#{list} init_on_alloc=1 init_on_free=1"
        secs += ' slab_nomerge pti=on slub_debug=ZF vsyscall=none"'
        raise 'No default/grub found' unless File.exist? conf

        unless search(conf, 'GRUB_CMDLINE_LINUX=')
          File.write(conf, "#{secs}\n", mode: 'a')
        end
      end
    end

    module Cryptsetup
      def encrypt(dev)
        raise "No device #{dev}" unless File.exist? dev

        puts " => Encrypting device #{dev}..."
        if Helpers.efi? && Getch::OPTIONS[:os] == 'gentoo'
          Helpers.sys("cryptsetup luksFormat --type luks #{dev}")
        else
          Helpers.sys("cryptsetup luksFormat --type luks1 #{dev}")
        end
      end

      def open_crypt(dev, map_name)
        raise "No device #{dev}" unless File.exist? dev

        puts " => Opening encrypted device #{dev}..."
        if Helpers.efi? && Getch::OPTIONS[:os] == 'gentoo'
          Helpers.sys("cryptsetup open --type luks #{dev} #{map_name}")
        else
          Helpers.sys("cryptsetup open --type luks1 #{dev} #{map_name}")
        end
      end
    end
  end
end
