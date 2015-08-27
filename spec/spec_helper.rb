require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'i18n-docs'

module Helpers

  def fixture_path
    File.join(File.expand_path(File.dirname(__FILE__)), 'fixtures')
  end

  def tmp_dir
    File.join(fixture_path, 'tmp')
  end

  def create_tmp_dir
    FileUtils::mkdir(tmp_dir) if ! File.exists?(tmp_dir)
  end

  def remove_tmp_dir
    FileUtils::rmtree(tmp_dir)
  end

  def remove_output_dir
    FileUtils.rm_rf(Dir.glob(File.join(fixture_path,'output','*')))
  end

end
