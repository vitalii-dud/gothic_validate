module Validator
  class UnregisteredRuleType < StandardError; end

  def self.included(included_class)
    included_class.extend(ClassMethods)
  end

  module ClassMethods
    def validate(attribute, **options)
      options.each do |type, rule|
        add_rule(attribute.to_sym, build_rule(type.to_sym, rule))
      end
    end

    def validation_schema
      @validation_schema ||= {}
    end

    private

    def build_rule(type, rule)
      {
        type: type,
        value: rule
      }
    end

    def add_rule(attribute, rule)
      init_empty_attribute_validation(attribute) unless validation_schema[attribute.to_sym]
      validation_schema[attribute.to_sym][rule[:type]] = rule[:value]
    end

    def init_empty_attribute_validation(attribute)
      validation_schema[attribute.to_sym] = {}
    end
  end

  def valid?
    reset_validation_errors
    self.class.validation_schema.each { |attribute, rules| apply_rules(attribute, rules) }

    validation_errors.count == 0
  end

  def validate!
    valid?
    validation_errors.count == 0 ? true : validation_errors
  end

  private

  def apply_rules(attribute, rules)
    rules.map do |type, rule|
      send("_validate_#{type}".to_sym, attribute, public_send(attribute), rule)
    end
  end

  def validation_errors
    @validation_errors ||= {}
  end

  def add_error(attribute, message)
    validation_errors[attribute] ||= []
    validation_errors[attribute] << message
  end

  def reset_validation_errors
    @validation_errors = {}
  end

  def _validate_presence(attribute, attr_value, desired_state)
    add_error(attribute, "#{attribute} should #{'not ' unless desired_state}be present!") unless (desired_state ? _present?(attr_value) : !_present?(attr_value))
  end

  def _validate_format(attribute, attr_value, format)
    add_error(attribute, "#{attribute} has invalid format!") unless attr_value =~ format
  end

  def _validate_type(attribute, attr_value, type)
    add_error(attribute, "#{attribute} should be an instance of #{type.name}!") unless attr_value.is_a?(type)
  end

  def _present?(value = nil)
    value.respond_to?(:empty?) ? !value.empty? : value
  end
end