# -*- coding: utf-8 -*-
module ActiveRecord::Turntable
  class Padrinotie
    Padrino::Tasks.files << File.dirname(__FILE__) + "/padrinoties/databases.rb"

    # padrino loading hook
    Padrino.before_load do
      ActiveRecord::Base.send(:include, ActiveRecord::Turntable)

      require 'generators/padrino/turntable/install_generators'
    end
    # # Swap QueryCache Middleware
    # initializer "turntable.swap_query_cache_middleware" do |app|
    #   app.middleware.swap ActiveRecord::QueryCache, ActiveRecord::Turntable::Rack::QueryCache
    # end
  end
end
