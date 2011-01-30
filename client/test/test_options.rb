#
# Test tpkg command line options
#

require "./#{File.dirname(__FILE__)}/tpkgtest"
require 'open3'

class TpkgOptionTests < Test::Unit::TestCase
  include TpkgTests
  
  def setup
    Tpkg::set_prompt(false)
    @testroot = Tempdir.new("testroot")
  end
  
  def test_help
    output = nil
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    IO.popen("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --help") do |pipe|
      output = pipe.readlines
    end
    # Make sure at least something resembling help output is there
    assert(output.any? {|line| line.include?('Usage: tpkg')}, 'help output content')
    # Make sure it fits on the screen
    assert(output.all? {|line| line.length <= 80}, 'help output columns')
    # Too many options for 23 lines
    #assert(output.size <= 23, 'help output lines')
  end
  
  def test_qenv
    output = nil
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    IO.popen("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --qenv") do |pipe|
      output = pipe.readlines
    end
    # Make sure the expected lines are there
    assert(output.any? {|line| line.include?('Operating System:')})
    assert(output.any? {|line| line.include?('Architecture:')})
  end
  
  def test_qconf
    output = nil
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    IO.popen("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --qconf") do |pipe|
      output = pipe.readlines
    end
    # Make sure the expected lines are there
    assert(output.any? {|line| line.include?('Base:')})
    assert(output.any? {|line| line.include?('Sources:')})
    assert(output.any? {|line| line.include?('Report server:')})
  end
  
  def test_use_ssh_key
    # Test --use-ssh-key with argument
    error = nil
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    Open3.popen3("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} -s shell.sourceforge.net --use-ssh-key no_such_file --no-sudo --version") do |stdin, stdout, stderr|
      stdin.close
      error = stderr.readlines
    end
    # Make sure the expected lines are there
    assert(error.any? {|line| line.include?('Unable to read ssh key from no_such_file')})
    
    # Test --use-ssh-key without argument
    output = nil
    error = nil
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    Open3.popen3("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} -s shell.sourceforge.net --use-ssh-key --version") do |stdin, stdout, stderr|
      stdin.close
      output = stdout.readlines
      error = stderr.readlines
    end
    # Make sure that tpkg didn't prompt for a password
    assert(!output.any? {|line| line.include?('SSH Password (leave blank if using ssh key):')})
    
    # Just to make sure our previous test is valid, check that we are prompted
    # for a password if we don't specify --use-ssh-key
    output = nil
    error = nil
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    Open3.popen3("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} -s shell.sourceforge.net --version") do |stdin, stdout, stderr|
      stdin.close
      output = stdout.readlines
      error = stderr.readlines
    end
    # Make sure that tpkg did prompt for a password this time
    assert(output.any? {|line| line.include?('SSH Password (leave blank if using ssh key):')})
  end
  
  def test_base
    # Test the --base option
    output = nil
    clibase = Tempdir.new("tpkgbase")
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    IO.popen("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --base #{clibase} --qconf") do |pipe|
      output = pipe.readlines
    end
    # Make sure the expected line is there
    baseline = output.find {|line| line.include?('Base: ')}
    assert_equal("Base: #{clibase}\n", baseline)
  end
    
  def test_base_precedence
    # Test precedence of various methods of setting base directory
    
    # TPKG_HOME ends up set in our environment due to use of the tpkg library
    ENV.delete('TPKG_HOME')
    
    FileUtils.mkdir_p(File.join(@testroot, Tpkg::DEFAULT_CONFIGDIR))
    File.open(File.join(@testroot, Tpkg::DEFAULT_CONFIGDIR, 'tpkg.conf'), 'w') do |file|
      file.puts "base = /confbase"
    end
    
    output = nil
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    # --base, TPKG_HOME and config file all set
    IO.popen("env TPKG_HOME=/envbase ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --base /clibase --test-root #{@testroot} --qconf") do |pipe|
      output = pipe.readlines
    end
    # Make sure the expected line is there
    baseline = output.find {|line| line.include?('Base: ')}
    assert_equal("Base: #{File.join(@testroot, 'clibase')}\n", baseline)
    
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    # TPKG_HOME and config file all set
    IO.popen("env TPKG_HOME=/envbase ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --test-root #{@testroot} --qconf") do |pipe|
      output = pipe.readlines
    end
    # Make sure the expected line is there
    baseline = output.find {|line| line.include?('Base: ')}
    assert_equal("Base: #{File.join(@testroot, 'envbase')}\n", baseline)
    
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    # Only config file set
    IO.popen("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --test-root #{@testroot} --qconf") do |pipe|
      output = pipe.readlines
    end
    # Make sure the expected line is there
    baseline = output.find {|line| line.include?('Base: ')}
    assert_equal("Base: #{File.join(@testroot, 'confbase')}\n", baseline)
    
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    # Nothing is set
    File.delete(File.join(@testroot, Tpkg::DEFAULT_CONFIGDIR, 'tpkg.conf'))
    IO.popen("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --test-root #{@testroot} --qconf") do |pipe|
      output = pipe.readlines
    end
    # Make sure the expected line is there
    baseline = output.find {|line| line.include?('Base: ')}
    assert_equal("Base: #{File.join(@testroot, Tpkg::DEFAULT_BASE)}\n", baseline)
  end
  
  def test_test_root
    # Test the --test-root option
    output = nil
    
    # With --test-root the base directory will be /<testroot>/opt/tpkg
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    IO.popen("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --test-root #{@testroot} --qconf") do |pipe|
      output = pipe.readlines
    end
    # Make sure the expected line is there
    baseline = output.find {|line| line.include?('Base: ')}
    assert_equal("Base: #{File.join(@testroot, Tpkg::DEFAULT_BASE)}\n", baseline)
    
    # Without --test-root the base directory will be something else (depending
    # on what config files are on the system)
    # The File.join(blah) is roughly equivalent to '../bin/tpkg'
    parentdir = File.dirname(File.dirname(__FILE__))
    IO.popen("ruby -I #{File.join(parentdir, 'lib')} #{File.join(parentdir, 'bin', 'tpkg')} --qconf") do |pipe|
      output = pipe.readlines
    end
    # This is a rather lame test, but we don't have any way to know how tpkg
    # is configured on the system on which the tests are running.
    baseline = output.find {|line| line.include?('Base: ')}
    assert_not_equal("Base: #{File.join(@testroot, Tpkg::DEFAULT_BASE)}\n", baseline)
  end
  
  def teardown
  end
end

