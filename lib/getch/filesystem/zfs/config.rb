module Getch
  module FileSystem
    module Zfs
      class Config < Getch::FileSystem::Zfs::Device
        def initialize
          super
          gen_uuid
          @root_dir = MOUNTPOINT
          @init = '/usr/lib/systemd/systemd'
        end

        def fstab
          file = "#{@root_dir}/etc/fstab"
          datas = data_fstab
          File.write(file, datas.join("\n"))
        end

        def systemd_boot
          return if ! Helpers::efi? 
          esp = '/boot/efi'
          dir = "#{@root_dir}/#{esp}/loader/entries/"
          datas_gentoo = [
            'title Gentoo Linux',
            'linux /vmlinuz',
            'initrd /initramfs',
            "options resume=UUID=#{@uuid_swap} root=#{@pool_name}/ROOT/gentoo init=#{@init} dozfs rw"
          ]
          File.write("#{dir}/gentoo.conf", datas_gentoo.join("\n"))
        end

        def grub
          return if Helpers::efi?
          file = "#{@root_dir}/etc/default/grub"
          cmdline = [ 
            "GRUB_CMDLINE_LINUX=\"resume=UUID=#{@uuid_swap} root=#{@pool_name}/ROOT/gentoo init=#{@init} dozfs rw\""
          ]
          File.write("#{file}", cmdline.join("\n"), mode: 'a')
        end

        private

        def gen_uuid
          @uuid_swap = `lsblk -o "UUID" #{@lv_swap} | tail -1`.chomp() if @dev_swap
          @uuid_root = `lsblk -o "UUID" #{@lv_root} | tail -1`.chomp() if @dev_root
          @uuid_dev_root = `lsblk -o "UUID" #{@dev_root} | tail -1`.chomp() if @dev_root
          @uuid_boot = `lsblk -o "UUID" #{@dev_boot} | tail -1`.chomp() if @dev_boot
          @uuid_boot_efi = `lsblk -o "UUID" #{@dev_boot_efi} | tail -1`.chomp() if @dev_boot_efi
        end

        def data_fstab
          boot_efi = @dev_boot_efi ? "UUID=#{@uuid_boot_efi} /boot/efi vfat noauto,noatime 1 2" : ''
          swap = @lv_swap ? "UUID=#{@uuid_swap} none swap discard 0 0" : ''

          [ boot_efi, swap ]
        end
      end
    end
  end
end
