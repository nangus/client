

#
# Test tpkg's compression feature
#

require "./#{File.dirname(__FILE__)}/tpkgtest"

class TpkgCompressTests < Test::Unit::TestCase
  include TpkgTests
  def setup
    Tpkg::set_prompt(false)
    # Make up our regular test package
    @pkgfile = make_package(:remove => ['operatingsystem', 'architecture', 'posix_acl', 'windows_acl'])
    @gzip_pkgfile = make_package(:change => {'name' => 'gzip_pkg'}, :remove => ['operatingsystem', 'architecture', 'posix_acl', 'windows_acl'], :compress => 'gzip')
    @bz2_pkgfile = make_package(:change => {'name' => 'bz2_pkg'}, :remove => ['operatingsystem', 'architecture', 'posix_acl', 'windows_acl'], :compress => 'bz2')

    # Make up a package that has been compressed by gzip
    @testroot = Tempdir.new("testroot")
  end

  # Given a .tpkg file, verify that we can figure out how the inner level archive tpkg.tar 
  # was compressed 
  def test_get_compression
    assert(Tpkg::get_compression(@pkgfile).nil?)
    assert_equal('gzip', Tpkg::get_compression(@gzip_pkgfile))
    assert_equal('bz2', Tpkg::get_compression(@bz2_pkgfile))
  end 

  def test_install_compressed_pkg
    tpkg = Tpkg.new(:file_system_root => @testroot, :base => File.join('home', 'tpkg'), :sources => [@gzip_pkgfile, @bz2_pkgfile])
    assert_nothing_raised { tpkg.install([@gzip_pkgfile], PASSPHRASE) }
    assert_nothing_raised { tpkg.install([@bz2_pkgfile], PASSPHRASE) }
  end

  def test_bad_compression_type
    assert_raise(RuntimeError, 'verify bad compression type')  { 
      make_package(:change => {'name' => 'bogus_compression_pkg'}, 
                   :remove => ['operatingsystem', 'architecture', 'posix_acl', 'windows_acl'], :compress => 'bogus')
    }
  end

  def teardown
    FileUtils.rm_f(@pkgfile)
    FileUtils.rm_f(@gzip_pkgfile)
    FileUtils.rm_f(@bz2_pkgfile)
    FileUtils.rm_rf(@testroot)
  end 
end 
