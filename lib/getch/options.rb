require 'optparse'

module Getch
  class Options
    attr_reader :language, :zoneinfo, :keymap, :disk, :fs, :username, :boot_disk, :cache_disk, :home_disk, :encrypt, :verbose

    def initialize(argv)
      @language = DEFAULT_OPTIONS[:language]
      @zoneinfo = DEFAULT_OPTIONS[:zoneinfo]
      @keymap = DEFAULT_OPTIONS[:keymap]
      @disk = DEFAULT_OPTIONS[:disk]
      @fs = DEFAULT_OPTIONS[:fs]
      @username = DEFAULT_OPTIONS[:username]
      @boot_disk = DEFAULT_OPTIONS[:boot_disk]
      @cache_disk = DEFAULT_OPTIONS[:cache_disk]
      @home_disk = DEFAULT_OPTIONS[:home_disk]
      @encrypt = DEFAULT_OPTIONS[:encrypt]
      @verbose = DEFAULT_OPTIONS[:verbose]
      parse(argv)
    end

    private

    def parse(argv)
      OptionParser.new do |opts|
        opts.on("-l", "--language LANG", "Default is en_US") do |lang|
          @language = lang
        end
        opts.on("-z", "--zoneinfo ZONE", "Default is US/Eastern") do |zone|
          @zoneinfo = zone
        end
        opts.on("-k", "--keymap KEY", "Default is us") do |key|
          @keymap = key
        end
        opts.on("-d", "--disk DISK", "Disk where install Gentoo (sda,sdb), default use #{@disk}") do |disk|
          @disk = Getch::Guard.disk(disk)
        end
        opts.on("-f", "--format FS", "Can be ext4, lvm or zfs. Default use ext4") do |fs|
          @fs = Getch::Guard.format(fs)
          DEFAULT_OPTIONS[:fs] = fs # dont known why, but it should be enforce
        end
        opts.on("-u", "--username USERNAME", "Create a new user /home/USERNAME with password.") do |user|
          @username = user
        end
        opts.on("--separate-boot DISK", "Disk for the boot/efi partition, default use #{@disk}") do |boot|
          @boot_disk = Getch::Guard.disk(boot)
          DEFAULT_OPTIONS[:boot_disk] = boot
        end
        opts.on("--separate-cache DISK", "Disk for the swap partition, add ZIL/L2ARC for ZFS when set, default use #{@disk}") do |swap|
          @cache_disk = Getch::Guard.disk(swap)
          DEFAULT_OPTIONS[:cache_disk] = swap
        end
        opts.on("--separate-home DISK", "Disk for the /home partition, default is nil") do |home|
          @home_disk = Getch::Guard.disk(home)
          DEFAULT_OPTIONS[:home_disk] = home
        end
        opts.on("--encrypt", "Encrypt your system.") do
          @encrypt = true
        end
        opts.on("--verbose", "Write more messages to the standard output.") do
          @verbose = true
        end
        opts.on("-h", "--help", "Display this") do
          puts opts
          exit
        end
      end.parse!(into: DEFAULT_OPTIONS)
    end
  end
end
