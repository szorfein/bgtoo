# frozen_string_literal: true

require_relative 'getch/helpers'
require_relative 'getch/options'
require_relative 'getch/states'
require_relative 'getch/gentoo'
require_relative 'getch/void'
require_relative 'getch/filesystem'
require_relative 'getch/tree'
require_relative 'getch/assembly'
require_relative 'getch/command'
require_relative 'getch/log'
require_relative 'getch/config'
require_relative 'getch/guard'
require_relative 'getch/version'

module Getch

  OPTIONS = {
    boot_disk: false,
    disk: false,
    cache_disk: false,
    encrypt: false,
    fs: 'ext4',
    home_disk: false,
    keymap: 'us',
    language: 'en_US',
    mountpoint: '/mnt/getch',
    musl: false,
    os: 'gentoo',
    username: false,
    verbose: false,
    vg_name: 'vg4',
    timezone: 'UTC'
  }

  STATES = {
    partition: false,
    format: false,
    mount: false,
    tarball: false,
    pre_config: false,
    update: false,
    post_config: false,
    terraform: false,
    bootloader: false,
    finalize: false,
  }

  MOUNTPOINT = '/mnt/getch'

  class Main
    def initialize(argv)
      argv[:cli]
      @log = Log.new
      Getch::States.new # Update States
    end

    def resume
      @log.fatal 'No disk, use at least getch with -d DISK' unless OPTIONS[:disk]

      puts "\nBuild " + OPTIONS[:os].capitalize + " Linux with the following args:\n"
      puts
      puts "\tLang: #{OPTIONS[:language]}"
      puts "\tZoneinfo: #{OPTIONS[:zoneinfo]}"
      puts "\tKeymap: #{OPTIONS[:keymap]}"
      puts "\tDisk: #{OPTIONS[:disk]}"
      puts "\tFilesystem: #{OPTIONS[:fs]}"
      puts "\tUsername: #{OPTIONS[:username]}"
      puts "\tEncrypt: #{OPTIONS[:encrypt]}"
      puts
      puts "\tseparate-boot disk: #{OPTIONS[:boot_disk]}"
      puts "\tseparate-cache disk: #{OPTIONS[:cache_disk]}"
      puts "\tseparate-home disk: #{OPTIONS[:home_disk]}"
      puts
      print 'Continue? (y,N) '
      case gets.chomp
      when /^y|^Y/
      else
        exit
      end
    end

    def prepare_disk
      assembly = Assembly.new
      assembly.clean
      assembly.partition
      assembly.format
      assembly.mount
    end

    def install_system
      assembly = Assembly.new
      assembly.tarball
      assembly.pre_config
      assembly.update
      assembly.post_config
    end

    def terraform
      Assembly.new.terraform
    end

    def bootloader
      Assembly.new.bootloader
    end

    def finalize
      Assembly.new.finalize
    end

    def configure
      config = Getch::Config::Main.new
      config.ethernet
      config.wifi
      config.dns
      config.sysctl
      config.shell
    end
  end
end
