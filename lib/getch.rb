require_relative 'getch/options'
require_relative 'getch/states'
require_relative 'getch/mount'
require_relative 'getch/gentoo'
require_relative 'getch/filesystem'
require_relative 'getch/helpers'

module Getch

  DEFAULT_OPTIONS = {
    language: 'en_US',
    location: 'US/Eastern',
    keyboard: 'us',
    disk: 'sda',
    fs: 'ext4',
    username: nil
  }.freeze

  STATES = {
    :partition => false,
    :format => false,
    :mount => false,
    :gentoo_base => false,
    :gentoo_config => false,
    :gentoo_update => false,
    :gentoo_kernel => false
  }

  MOUNTPOINT = "/mnt/gentoo".freeze
  OPTIONS_FS = {
    'ext4' => Getch::FileSystem::Ext4
  }.freeze

  def self.resume_options(opts)
    puts "\nBuild Gentoo with the following args:\n"
    puts "lang: #{opts.language}"
    puts "zoneinfo: #{opts.zoneinfo}"
    puts "keyboard: #{opts.keyboard}"
    puts "disk: #{opts.disk}"
    puts "fs: #{opts.fs}"
    puts "username: #{opts.username}"
    puts
    print "Continue? (n,y) "
    case gets.chomp
    when /^y|^Y/
      return
    else
      exit 1
    end
  end

  def self.format(disk, fs, user)
    return if STATES[:format] and STATES[:partition]
    puts
    print "Partition and format disk #{disk}, this will erase all data, continue? (n,y) "
    case gets.chomp
    when /^y|^Y/
      filesystem = OPTIONS_FS[fs].new(disk)
      filesystem.cleaning
      filesystem.partition
      filesystem.format
      filesystem::Mount.new(disk, user).run
    else
      exit 1
    end
  end

  def self.init_gentoo(options)
    gentoo = Getch::Gentoo
    gentoo.stage3
    gentoo.config(options)
    gentoo.chroot
    gentoo.kernel
    gentoo.boot(options)
  end

  def self.main(argv)
    options = Options.new(argv)
    resume_options(options)
    Getch::States.new() # Update States
    format(options.disk, options.fs, options.username)
    init_gentoo(options)
  end
end
