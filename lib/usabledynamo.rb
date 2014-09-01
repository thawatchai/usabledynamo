# Include hook code here
require 'usabledynamo/usabledynamo'

module UsableDynamo
  class Engine < Rails::Engine
  end if defined?(Rails) && Rails::VERSION::MAJOR >= 3
end

