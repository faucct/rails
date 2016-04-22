module ActiveRecord
  class PredicateBuilder
    class ThroughAssociationQueryHandler < AssociationQueryHandler # :nodoc:
      def call(attribute, value)
        table = value.through_table

        predicates = []

        if (through_relation = value.through_relation)
          predicates << predicate_builder.build_from_hash(
            table.association_primary_key.to_s => through_relation
          ).reduce(:and)
        end

        if value.includes_nil?
          nodes = predicate_builder.build_from_hash(
            table.association_primary_key.to_s => value.all_through_foreign_keys
          )
          predicates << Arel::Nodes::Grouping.new(nodes.map do |predicate|
            Relation::WhereClause.invert_predicate(predicate)
          end.reduce(:and))
        end

        predicates.reduce(:or)
      end
    end

    class ThroughAssociationQueryValue < AssociationQueryValue # :nodoc:
      def through_table
        associated_table.through_table
      end

      def through_relation
        if source_values
          through_table.relation.where(associated_table.source_name => source_values).select(through_table.association_foreign_key)
        end
      end

      def all_through_foreign_keys
        through_table = associated_table.through_table
        through_table.relation.where.not(associated_table.source_name => nil).select(through_table.association_foreign_key)
      end

      def source_values
        case value
        when Array
          values = value.select(&:itself)
          values if values.any? || value == []
        else
          value
        end
      end

      def includes_nil?
        case value
        when Array
          !value.all?(&:itself)
        else
          !value
        end
      end
    end
  end
end
