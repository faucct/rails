module ActiveRecord
  class PredicateBuilder
    class BelongsToAssociationQueryHandler < AssociationQueryHandler # :nodoc:
      def call(attribute, value)
        queries = {}

        table = value.associated_table
        if value.base_class
          queries[table.association_foreign_type.to_s] = value.base_class.name
        end

        queries[table.association_foreign_key.to_s] = value.ids
        predicate_builder.build_from_hash(queries)
      end
    end

    class BelongsToAssociationQueryValue < AssociationQueryValue # :nodoc:
      def ids
        case value
        when Relation
          value.select(primary_key)
        when Array
          value.map { |v| convert_to_id(v) }
        else
          convert_to_id(value)
        end
      end

      def base_class
        if associated_table.polymorphic_association?
          @base_class ||= polymorphic_base_class_from_value
        end
      end

      private

      def primary_key
        associated_table.association_primary_key(base_class)
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
    end
  end
end
