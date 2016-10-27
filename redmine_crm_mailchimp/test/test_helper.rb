# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require 'webmock/minitest'

require Redmine::Plugin.find(:redmine_contacts).directory + '/test/test_helper'