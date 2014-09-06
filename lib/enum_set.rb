require "enum_set/version"

module EnumSet
  EnumError = Class.new(NameError)

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def enum_set(enums)
      enums.each do |column, names|
        names.map!(&:to_sym)
        names_with_bits = names.each_with_index.map { |name, i| [name, 1 << i] }

        define_method :"#{column}_bitfield" do
          self[column] || 0
        end

        names_with_bits.each do |name, bit|
          define_method :"#{name}?" do
            (bit & send("#{column}_bitfield")) != 0
          end

          scope :"#{name}", -> {
            where("#{column} & ? <> 0", bit)
          }
        end

        define_method :"#{column}=" do |array|
          new_value = send("#{column}_bitfield")

          array.each do |val|
            raise EnumError.new("Unrecognized value for #{column}: #{val.inspect}") unless names.include?(val)
          end

          array.each do |val|
            bit = names_with_bits.find { |name,_| name == val.to_sym }.last
            new_value |= bit
          end

          self[column] = new_value
          send(column)
        end

        define_method column do
          names.select { |name| send(:"#{name}?") }
        end
      end
    end
  end
end
