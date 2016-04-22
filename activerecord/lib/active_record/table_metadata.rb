module ActiveRecord
  class TableMetadata # :nodoc:
    delegate :foreign_type, :foreign_key, to: :association, prefix: true
    delegate :association_primary_key, to: :association

    def initialize(klass, arel_table, association = nil)
      @klass = klass
      @arel_table = arel_table
      @association = association
    end
    attr_reader :klass

    def resolve_column_aliases(hash)
      # This method is a hot spot, so for now, use Hash[] to dup the hash.
      #   https://bugs.ruby-lang.org/issues/7166
      new_hash = Hash[hash]
      hash.each do |key, _|
        if (key.is_a?(Symbol)) && klass.attribute_alias?(key)
          new_hash[klass.attribute_alias(key)] = new_hash.delete(key)
        end
      end
      new_hash
    end

    def arel_attribute(column_name)
      if klass
        klass.arel_attribute(column_name, arel_table)
      else
        arel_table[column_name]
      end
    end

    def type(column_name)
      if klass
        klass.type_for_attribute(column_name.to_s)
      else
        Type::Value.new
      end
    end

    def associated_with?(association_name)
      klass && klass._reflect_on_association(association_name)
    end

    def associated_table(table_name)
      return self if table_name == arel_table.name

      association = klass._reflect_on_association(table_name)
      if association && !association.polymorphic?
        association_klass = association.klass
        arel_table = association_klass.arel_table.alias(table_name)
      else
        type_caster = TypeCaster::Connection.new(klass, table_name)
        association_klass = nil
        arel_table = Arel::Table.new(table_name, type_caster: type_caster)
      end

      TableMetadata.new(association_klass, arel_table, association)
    end

    def polymorphic_association?
      belongs_to_association? && association.polymorphic?
    end

    def belongs_to_association?
      association && association.belongs_to?
    end

    def through_association?
      association && association.through_reflection
    end

    def through_table
      through_reflection = association.through_reflection
      TableMetadata.new(through_reflection.klass, through_reflection.klass.arel_table, through_reflection)
    end

    def source_name
      association && association.source_reflection.name
    end

    def relation
      if association && association.scope
        klass.all.instance_exec(&association.scope)
      else
        klass.all
      end
    end

    protected

    attr_reader :arel_table, :association
  end
end
