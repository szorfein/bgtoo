module Getch
  module Gentoo
    class Sources
      def initialize
        @lsmod = `lsmod`.chomp
        @filesystem = Getch.class_fs::Deps.new()
      end

      def build_others
        cryptsetup
        virtualbox_guest
        qemu_guest
        install_wifi
        install_audio
      end

      def build_kspp
        puts "Adding KSPP to the kernel source"
        bask("-b -a systemd")
      end

      def make
        if DEFAULT_OPTIONS[:fs] == 'lvm' || DEFAULT_OPTIONS[:fs] == 'zfs' || DEFAULT_OPTIONS[:encrypt]
          @filesystem.make
        else
          make_kernel
        end
      end

      private

      def make_kernel
        puts "Compiling kernel sources"
        cmd = "make -j$(nproc) && make modules_install && make install"
        Getch::Make.new(cmd).run!
        is_kernel = Dir.glob("#{MOUNTPOINT}/boot/vmlinuz-*")
        raise "No kernel installed, compiling source fail..." if is_kernel == []
      end

      def cryptsetup
        return unless DEFAULT_OPTIONS[:encrypt]
        make_conf = "#{MOUNTPOINT}/etc/portage/make.conf"

        puts "Adding support for cryptsetup."
        bask("-a cryptsetup")
        Getch::Chroot.new("euse -E cryptsetup").run! unless Helpers::grep?(make_conf, /cryptsetup/)
        Getch::Emerge.new("sys-fs/cryptsetup").pkg!
      end

      def virtualbox_guest
        systemd=`systemd-detect-virt`.chomp
        return if ! ismatch?('vmwgfx') || systemd.match(/none/)
        bask("-a virtualbox-guest")
        Getch::Emerge.new("app-emulation/virtualbox-guest-additions").pkg!
      end

      def qemu_guest
        bask("-a kvm-host") if ismatch?('kvm')
        bask("-a kvm-guest") if ismatch?('virtio')
      end

      def ismatch?(arg)
        @lsmod.match?(/#{arg}/)
      end

      def bask(cmd)
        Getch::Bask.new(cmd).run!
      end

      def install_wifi
        return if ! ismatch?('cfg80211')
        bask("-a wifi")
        wifi_drivers
        Getch::Emerge.new("net-wireless/iw wpa_supplicant net-wireless/iwd").pkg!
      end

      def install_audio
        return if ! ismatch?('snd_pcm')
        bask("-a sound")
      end

      def wifi_drivers
        bask("-a ath9k-driver") if ismatch?('ath9k')
      end
    end
  end
end
