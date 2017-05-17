require 'active_support'

module EasyRoles
  extend ActiveSupport::Concern

  ALLOWED_METHODS = %i[serialize bitmask].freeze
  ALLOWED_METHODS.each { |m| autoload m.to_s.capitalize.to_sym, "methods/#{m}" }

  class_methods do
    def easy_roles(name, options = {})
      begin
        raise NameError unless ALLOWED_METHODS.include? options[:method]
      rescue NameError
        puts "[Easy Roles] Storage method does not exist reverting to Serialize"
        options[:method] = :serialize
      end
      "EasyRoles::#{options[:method].to_s.camelize}".constantize.new(self, name, options)
    end
  end

  def respond_to_missing?(method_id, *args, &block)
    match = method_id.to_s.match(/^is_(\w+)[?]$/)
    if match && respond_to?('has_role?')
      self.class.send(:define_method, "is_#{match[1]}?") do
        send :has_role?, match[1].to_s
      end
      send "is_#{match[1]}?"
    else
      super(method_id, *args, &block)
    end
  end

  def respond_to?(method_id, include_private = false)
    match = method_id.to_s.match(/^is_(\w+)[?]$/)
    if match && respond_to?('has_role?')
      true
    else
      super(method_id, include_private)
    end
  end
end

ActiveRecord::Base.prepend EasyRoles
