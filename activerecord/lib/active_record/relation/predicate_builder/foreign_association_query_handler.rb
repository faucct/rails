module ActiveRecord
  class PredicateBuilder
    class ForeignAssociationQueryHandler < AssociationQueryHandler # :nodoc:
      def call(attribute, value)
        table = value.associated_table

        predicates = []

        if (foreign_keys = value.foreign_keys)
          predicates << predicate_builder.build_from_hash(
            table.association_primary_key.to_s => foreign_keys
          ).reduce(:and)
        end

        if value.includes_nil?
          nodes = predicate_builder.build_from_hash(table.association_primary_key.to_s => value.all_foreign_keys)
          predicates << nodes.map do |predicate|
            Relation::WhereClause.invert_predicate(predicate)
          end.reduce(:and)
        end

        predicates.reduce(:or)
      end
    end

    class ForeignAssociationQueryValue < AssociationQueryValue # :nodoc:
      def foreign_keys
        case value
        when Relation
          value.select(association_foreign_key)
        when Array
          if value.all? { |v| foreign_key?(v) }
            value.map { |v| convert_to_foreign_key(v) }
          end
        else
          if foreign_key?(value)
            convert_to_foreign_key(value)
          end
        end || foreign_keys_scope
      end

      def all_foreign_keys
        associated_table.relation.select(association_foreign_key)
      end

      def includes_nil?
        case value
        when Array
          value.any?(&:nil?)
        else
          value.nil?
        end
      end

      private

      def base_class
        associated_table.klass
      end

      def primary_key
        associated_table.association_primary_key(base_class)
      end

      def association_foreign_key
        associated_table.association_foreign_key
      end

      def polymorphic_base_class_from_value
        case value
        when Relation
          value.klass.base_class
        when Array
          val = value.compact.first
          val.class.base_class if val.is_a?(Base)
        when Base
          value.class.base_class
        end
      end

      def convert_to_id(value)
        case value
        when Base
          value._read_attribute(primary_key)
        else
          value
        end
      end

      def foreign_keys_scope
        case value
        when Array
          present_ids = value.map { |v| convert_to_id(v) }.compact
          return unless present_ids.any? || !includes_nil?
        else
          return unless value
          present_ids = value
        end
        associated_table.relation.where(primary_key => present_ids).select(association_foreign_key)
      end

      def foreign_key?(value)
        value.is_a?(Base)
      end

      def convert_to_foreign_key(value)
        value._read_attribute(association_foreign_key) if foreign_key?(value)
      end
    end
  end
end
