module ActiveRecord
  class PredicateBuilder
    class AssociationQueryHandler # :nodoc:
      def initialize(predicate_builder)
        @predicate_builder = predicate_builder
      end

      def call(attribute, value)
        fail NotImplementedError
      end

      protected

      attr_reader :predicate_builder

      def self.value_for(table, column, value)
        associated_table = table.associated_table(column)
        klass = if associated_table.polymorphic_association? && ::Array === value && value.first.is_a?(Base)
          PolymorphicArrayValue
        elsif associated_table.belongs_to_association?
          BelongsToAssociationQueryValue
        elsif associated_table.through_association?
          ThroughAssociationQueryValue
        else
          ForeignAssociationQueryValue
        end

        klass.new(associated_table, value)
      end
    end

    class AssociationQueryValue # :nodoc:
      attr_reader :associated_table, :value

      def initialize(associated_table, value)
        @associated_table = associated_table
        @value = value
      end
    end
  end
end
