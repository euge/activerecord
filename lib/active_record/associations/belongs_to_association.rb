module ActiveRecord
  module Associations
    class BelongsToAssociation < AssociationProxy #:nodoc:
      def create(attributes = {})
        replace(@reflection.create_association(attributes))
      end

      def build(attributes = {})
        replace(@reflection.build_association(attributes))
      end

      def replace(record)
        counter_cache_name = @reflection.counter_cache_column

        if record.nil?
          if counter_cache_name && !@owner.new_record?
            @reflection.klass.decrement_counter(counter_cache_name, previous_record_id) if @owner[@reflection.primary_key_name]
          end

          @target = @owner[@reflection.primary_key_name] = nil
        else
          raise_on_type_mismatch(record)

          if counter_cache_name && !@owner.new_record?
            @reflection.klass.increment_counter(counter_cache_name, record.id)
            @reflection.klass.decrement_counter(counter_cache_name, @owner[@reflection.primary_key_name]) if @owner[@reflection.primary_key_name]
          end

          @target = (AssociationProxy === record ? record.target : record)
          @owner[@reflection.primary_key_name] = record_id(record) unless record.new_record?
          @updated = true
        end

        loaded
        record
      end
      
      def updated?
        @updated
      end
      
      private
        def find_target
          if IdentityMap.enabled? && (p = @owner[@reflection.primary_key_name]) && (t = IdentityMap.get(@reflection.klass, p))
            return t
          end
          
          find_method = if @reflection.options[:primary_key]
                          "find_by_#{@reflection.options[:primary_key]}"
                        else
                          "find"
                        end
          @reflection.klass.send(find_method,
            @owner[@reflection.primary_key_name],
            :select     => @reflection.options[:select],
            :conditions => conditions,
            :include    => @reflection.options[:include],
            :readonly   => @reflection.options[:readonly]
          ) if @owner[@reflection.primary_key_name]
        end

        def foreign_key_present
          !@owner[@reflection.primary_key_name].nil?
        end

        def record_id(record)
          record.send(@reflection.options[:primary_key] || :id)
        end

        def previous_record_id
          @previous_record_id ||= if @reflection.options[:primary_key]
                                    previous_record = @owner.send(@reflection.name)
                                    previous_record.nil? ? nil : previous_record.id
                                  else
                                    @owner[@reflection.primary_key_name]
                                  end
        end
    end
  end
end
