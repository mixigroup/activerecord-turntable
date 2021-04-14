require 'thor/group'

module Padrino
  module Generators
    Padrino::Generators.load_components!

    class Turntable < Thor::Group
      Padrino::Generators.add_generator(:turntable, self)

      def self.source_root
        File.expand_path("../../../templates", __FILE__)
      end

      desc "Creates turntable configuration file (config/turntable.yml)"

      include Thor::Actions
      include Padrino::Generators::Actions
      include Padrino::Generators::Components::Actions

      desc "Creates turntable configuration file (config/turntable.yml)"

      def self.require_arguments?
        false
      end

      def create_turntable
        copy_file "turntable.yml", "config/turntable.yml"
      end
    end
  end
end
