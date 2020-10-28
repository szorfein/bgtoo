module Getch
  module FileSystem
    module Ext4
      module Encrypt
        class Partition < Getch::FileSystem::Ext4::Encrypt::Device
          def initialize
            super
            @state = Getch::States.new
            @partition = Getch::FileSystem::Partition.new
            @clean = Getch::FileSystem::Clean
            @log = Log.new
            run_partition
          end

          def run_partition
            return if STATES[:partition ]
            @clean.struct(@disk)
            @clean.hdd(@disk)
            if Helpers::efi?
              partition_efi
              encrypt_efi
            else
              partition_bios
              encrypt_bios
            end
            @state.partition
          end

          private

          # Follow https://wiki.archlinux.org/index.php/Partitioning
          def partition_efi
            # /efi  - EFI system partition - 260MB
            # swap  - Linux Swap - size of the ram
            # /     - Root
            # /home - Home
            @partition.efi(@dev_esp)
            @partition.swap(@dev_swap)
            @partition.root(@dev_root, "8309")
            @partition.home(@dev_home, "8309") if @dev_home
          end

          def encrypt_efi
            @log.info("Format root")
            Helpers::sys("cryptsetup luksFormat #{@dev_root}")
            @log.debug("Opening root")
            Helpers::sys("cryptsetup open --type luks #{@dev_root} cryptroot")
            encrypt_home
          end

          def encrypt_bios
            @log.info("Format root for bios")
            Helpers::sys("cryptsetup luksFormat --type luks1 #{@dev_root}")
            @log.debug("Opening root")
            Helpers::sys("cryptsetup open --type luks1 #{@dev_root} cryptroot")
            encrypt_home
          end

          def encrypt_home
            if @dev_home then
              create_secret_keys
              @log.info("Format home with #{@key_path}")
              Helpers::sys("cryptsetup luksFormat #{@dev_home} #{@key_path}")
              @log.debug("Open home with key #{@key_path}")
              exec("cryptsetup open --type luks -d #{@key_path} #{@dev_home} crypthome")
            end
          end

          def create_secret_keys
            return if ! @dev_home
            @log.info("Creating secret keys")
            keys_dir = "/root/secretkeys"
            key_name = "crypto_keyfile.bin"
            @key_path = "#{keys_dir}/#{key_name}"
            FileUtils.mkdir keys_dir, mode: 0700 if ! Dir.exist?(keys_dir)
            exec("dd bs=512 count=4 if=/dev/urandom of=#{@key_path}")
          end

          def partition_bios
            # None      - Bios Boot Partition - 1MiB
            # swap      - Linux Swap - size of the ram
            # /         - Root
            # /home     - Home
            @partition.gpt(@dev_esp)
            @partition.swap(@dev_swap)
            @partition.root(@dev_root, "8309")
            @partition.home(@dev_home, "8309") if @dev_home
          end

          def exec(cmd)
            Getch::Command.new(cmd).run!
          end
        end
      end
    end
  end
end
