# frozen_string_literal: true

module Getch
  module FileSystem
    module Zfs
      class Partition < Device
        def initialize
          super
          @partition = Getch::FileSystem::Partition.new
          @state = Getch::States.new
          @log = Getch::Log.new
          run_partition
        end

        def run_partition
          return if STATES[:partition ]

          partition
          cache
          @state.partition
        end

        private

        def partition
          if @efi
            @partition.efi(@dev_esp)
            @partition.boot(@dev_boot) if Getch::OPTIONS[:os] == 'void'
            @partition.swap(@dev_swap) unless @cache_disk
            @partition.root(@dev_root, 'BF00') if @root_part != 1
          else
            @partition.gpt(@dev_gpt)
            # Boot pool for GRUB2
            @partition.boot(@dev_boot)
            @partition.swap(@dev_swap) unless @cache_disk
            @partition.root(@dev_root, 'BF00') if @root_part != 1
          end
        end

        def cache
          return unless @cache_disk

          mem = `awk '/MemTotal/ {print $2}' /proc/meminfo`.chomp + 'K'
          exec("sgdisk -n1:0:+#{mem} -t1:8200 /dev/#{@cache_disk}")
          exec("sgdisk -n2:0:+4G -t2:BF07 /dev/#{@cache_disk}")
          exec("sgdisk -n3:0:0 -t3:BF00 /dev/#{@cache_disk}")
        end

        # Partition_efi
        # /efi      - EFI system partition - 260MB
        # /         - Root

        # Partition_bios
        # None      - Bios Boot Partition - 1MiB
        # /boot     - Boot - 8300
        # /         - Root

        def exec(cmd)
          Getch::Command.new(cmd)
        end
      end
    end
  end
end
