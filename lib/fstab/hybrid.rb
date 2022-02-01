
module Fstab
  # Hybrid for Lvm + Encryption
  class Hybrid < Encrypt
    def initialize(devs, options)
      super
      @vg = options[:vg_name] ||= 'vg0'
    end

    # The swap UUID based on the lvm volume /dev/vg/swap
    def write_swap
      dm = get_dm 'swap'
      uuid = gen_uuid dm
      line = "UUID=#{uuid} none swap sw 0 0"
      echo_a @conf, line
    end

    def write_root
      line = "/dev/#{@vg}/root #{@fs} rw,relatime 0 1"
      echo_a @conf, line
    end

    def write_home
      line = "/dev/#{@vg}/home #{@fs} rw,relatime 0 2"
      echo_a @conf, line
    end
  end
end
