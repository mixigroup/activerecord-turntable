module ActiveRecord::Turntable
  RackupFramework = Rails   if defined?(Rails);
  RackupFramework = Padrino if defined?(Padrino);

  module ConfigurationMethods
    DEFAULT_PATH = File.dirname(File.dirname(__FILE__))

    def turntable_configuration_file
      @turntable_configuration_file ||= File.join(turntable_app_root_path, "config/turntable.yml")
    end

    def turntable_configuration_file=(filename)
      @turntable_configuration_file = filename
    end

    def turntable_app_root_path
      defined?(ActiveRecord::Turntable::RackupFramework) ? ActiveRecord::Turntable::RackupFramework.root.to_s : DEFAULT_PATH
    end
  end
end
