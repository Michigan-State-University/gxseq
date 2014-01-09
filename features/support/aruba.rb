require 'aruba/cucumber'
Before('@turtle') do
  @aruba_io_wait_seconds = 3
  @aruba_timeout_seconds = 15
end
# Extension allowing for in-process tasks
module TestSupport
  module ArubaExt
    
    def with_redirected_stdout(&block)
      redirect_stdout
      yield
      bring_back_stdout
    end

    def mock_stdout
      unescape @stdout_cache
    end

    def mock_stderr
      unescape @stderr_cache
    end

    def mock_output
      mock_stdout + mock_stderr
    end

    private

    def redirect_stdout
      @stdout_cache = ''
      @stderr_cache = ''

      @stdout_redirected = true
      @orig_stdout = $stdout
      @orig_stderr = $stderr
      $stdout = @mock_stdout = StringIO.new
      $stderr = @mock_stderr = StringIO.new
    end

    def bring_back_stdout
      @stdout_cache = @mock_stderr.string
      @stderr_cache = @mock_stdout.string

      @stdout_redirected = false
      $stdout = @orig_stdout
      $stderr = @orig_stderr
      @orig_stdout = @mock_stdout = nil
      @orig_stderr = @mock_stderr = nil
    end
  end
end
 
World(TestSupport::ArubaExt)
