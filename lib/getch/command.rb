# frozen_string_literal: true

require 'open3'
require 'nito'
require 'English'

module Getch
  class Command
    attr_reader :res

    def initialize(*args)
      @cmd = args.join(' ')
      @log = Getch::Log.new
      x
    end

    def to_s
      @res
    end

    protected

    def x
      @log.info "Exec: #{@cmd}"
      cmd = build_cmd

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close_write
        code = wait_thr.value

        unless code.success?
          begin
            @log.debug stderr.readline until stderr.eof.nil?
          rescue EOFError
            print
          end
        end

        if code.success?
          @log.result_ok
          @res = stdout.read.chomp
          return
        end

        puts
        @log.error "#{@cmd} - #{code}"
        @log.fatal "Running #{@cmd}"
      end
    end

    private

    def build_cmd
      @cmd
    end
  end

  class Bask
    def initialize(cmd)
      @cmd = cmd
      @log = Log.new
      @version = '0.6'
      @config = "#{MOUNTPOINT}/etc/kernel/config.d"
      download_bask unless Dir.exist? "#{MOUNTPOINT}/root/bask-#{@version}"
    end

    def cp
      NiTo.mkdir @config
      NiTo.cp(
        "#{MOUNTPOINT}/root/bask-#{@version}/config.d/#{@cmd}",
        "#{@config}/#{@cmd}"
      )
    end

    def add(content)
      Helpers.add_file "#{@config}/#{@cmd}", content
    end

    private

    def download_bask
      @log.info "Installing Bask...\n"
      url = "https://github.com/szorfein/bask/archive/refs/tags/#{@version}.tar.gz"
      file = "bask-#{@version}.tar.gz"

      Dir.chdir("#{MOUNTPOINT}/root")
      Helpers.get_file_online(url, file)
      Getch::Command.new("tar xzf #{file}")
    end
  end

  class Chroot < Command
    def build_cmd
      dest = OPTIONS[:mountpoint]
      case OPTIONS[:os]
      when 'gentoo'
        "chroot #{dest} /bin/bash -c \"source /etc/profile; #{@cmd}\""
      when 'void'
        "chroot #{dest} /bin/bash -c \"#{@cmd}\""
      end
    end
  end

  class ChrootOutput
    def initialize(*args)
      @cmd = args.join(' ')
      @log = Log.new
      x
    end

    private

    def x
      msg
      system('chroot', OPTIONS[:mountpoint], '/bin/bash', '-c', other_args)
      $CHILD_STATUS.success? && return

      @log.fatal "Running #{@cmd}"
    end

    def msg
      @log.info "Exec: #{@cmd}...\n"
    end

    def other_args
      case OPTIONS[:os]
      when 'gentoo' then "source /etc/profile && #{@cmd}"
      when 'void' then @cmd
      end
    end
  end

  # Install
  # use system() to install packages
  # Usage: Install.new(pkg_name)
  class Install < ChrootOutput
    def msg
      @log.info "Installing #{@cmd}...\n"
    end

    # Gentoo binary should not use --changed-use
    # https://wiki.gentoo.org/wiki/Binary_package_guide
    def other_args
      case OPTIONS[:os]
      when 'gentoo'
        if OPTIONS[:binary]
          "source /etc/profile && emerge #{@cmd}"
        else
          "source /etc/profile && emerge --changed-use #{@cmd}"
        end
      when 'void' then "/usr/bin/xbps-install -y #{@cmd}" end
    end
  end
end
