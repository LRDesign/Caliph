module Caliph
  # This is the Caliph handle on a run process - it can be used to send signals
  # to running processes, wait for them to complete, get their exit status once
  # they have, and watch their streams in either case.
  class CommandRunResult
    def initialize(pid, command, shell)
      @command = command
      @pid = pid
      @shell = shell

      #####
      @process_status = nil
      @streams = {}
      @consume_timeout = nil
    end

    attr_reader :process_status

    attr_reader :pid, :command
    attr_accessor :consume_timeout, :streams

    # Access the stdout of the process
    def stdout
      @streams[1]
    end

    # Access the stderr of the process
    def stderr
      @streams[2]
    end

    # @return [exit_code] the raw exit of the process
    # @return [nil] the process is still running
    def exit_code
      if @process_status.nil?
        return nil
      else
        @process_status.exitstatus
      end
    end
    alias exit_status exit_code

    # Check whether the process is still running
    # @return [true] the process is still running
    # @return [false] the process has completed
    def running?
      !@process_status.nil?
    end

    # Confirm that the process exited with a successful exit code (i.e. 0).
    # This is pretty reliable, but many applications return bad exit statuses -
    # 0 when they failed, usually.
    def succeeded?
      must_succeed!
      return true
    rescue
      return false
    end
    alias succeeds? succeeded?

    # Nicely formatted output of stdout and stderr - won't be intermixed, which
    # may be different than what you'd see live in the shell
    def format_streams
      "stdout:#{stdout.nil? || stdout.empty? ? "[empty]\n" : "\n#{stdout}"}" +
      "stderr:#{stderr.nil? || stderr.empty? ? "[empty]\n" : "\n#{stderr}"}---"
    end

    # Demands that the process succeed, or else raises and error
    def must_succeed!
      case exit_code
      when 0
        return exit_code
      else
        fail "Command '#{@command.string_format}' failed with exit status #{exit_code}: \n#{format_streams}"
      end
    end

    # Stop a running process. Sends SIGINT by default which about like hitting
    # Control-C.
    # @param signal the Unix signal to send to the process
    def kill(signal = nil)
      Process.kill(signal || "INT", pid)
    rescue Errno::ESRCH
      warn "Couldn't find process #{pid} to kill it"
    end

    # Waits for the process to complete. If this takes longer that
    # {consume_timeout}, output on the process's streams will be output via
    # {Shell#report} - very useful when compilation or network transfers are
    # taking a long time.
    def wait
      @accumulators = {}
      waits = {}
      @buffered_echo = []

      ioes = streams.values
      ioes.each do |io|
        @accumulators[io] = []
        waits[io] = 3
      end
      begin_echoing = Time.now + (@consume_timeout || 3)

      @live_ioes = ioes.dup

      until @live_ioes.empty? do
        newpid, @process_status = Process.waitpid2(pid, Process::WNOHANG)

        unless @process_status.nil?
          consume_buffers(@live_ioes)
          break
        end

        timeout = 0

        if !@buffered_echo.nil?
          timeout = begin_echoing - Time.now
          if timeout < 0
            @shell.report ""
            @shell.report "Long running command output:"
            @shell.report @buffered_echo.join
            @buffered_echo = nil
          end
        end

        if timeout > 0
          result = IO::select(@live_ioes, [], @live_ioes, timeout)
        else
          result = IO::select(@live_ioes, [], @live_ioes, 1)
        end

        unless result.nil? #timeout
          readable, _writeable, errored = *result
          unless errored.empty?
            raise "Error on IO: #{errored.inspect}"
          end

          consume_buffers(readable)
        end
      end

      if @process_status.nil?
        newpid, @process_status = Process.waitpid2(pid)
      end

      ioes.each do |io|
        io.close
      end
      @streams = Hash[ioes.each_with_index.map{|io, index| [index + 1, @accumulators[io].join]}]
    end

    def consume_buffers(readable)
      if not(readable.nil? or readable.empty?)
        readable.each do |io|
          begin
            while chunk = io.read_nonblock(4096)
              if @buffered_echo.nil?
                @shell.report chunk, false
              else
                @buffered_echo << chunk
              end
              @accumulators[io] <<  chunk
            end
          rescue IO::WaitReadable => ex
          rescue EOFError => ex
            @live_ioes.delete(io)
          end
        end
      end
    end
  end
end
