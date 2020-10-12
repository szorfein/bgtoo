require 'fileutils'

module Getch
  module FileSystem
    module Zfs
      class Mount < Getch::FileSystem::Zfs::Device
        def initialize
          super
          @root_dir = MOUNTPOINT
          @boot_dir = "#{@root_dir}/boot"
          @boot_efi_dir = "#{@root_dir}/boot/efi"
          @state = Getch::States.new()
        end

        def run
          return if STATES[:mount]
          mount_swap
          mount_root
          mount_boot
          mount_boot_efi
          run("zfs mount -a")
          @state.mount
        end

        private

        def mount_swap
          run("swapon #{@dev_swap}")
        end

        def mount_root
          Getch::Helpers::mkdir(@root_dir)
          run("zfs mount #{@pool_name}/ROOT/gentoo")
        end

        def mount_boot_efi
          return if ! @dev_boot_efi
          Getch::Helpers::mkdir(@boot_efi_dir)
          run("mount #{@dev_boot_efi} #{@boot_efi_dir}")
        end

        def mount_boot
          return if ! @dev_boot
          Getch::Helpers::mkdir(@boot_dir)
          run("zfs mount #{@boot_pool_name}/BOOT/gentoo")
        end

        def run(cmd)
          system(cmd)
          unless $?.success?
            raise "Error with #{cmd}"
          end
        end
      end
    end
  end
end
