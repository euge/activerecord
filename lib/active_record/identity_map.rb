module ActiveRecord

  module IdentityMap

    class << self
      def enabled=(flag)
        Thread.current[:identity_map_enabled] = flag
      end

      def enabled
        Thread.current[:identity_map_enabled]
      end
      alias enabled? enabled

      def repository
        Thread.current[:identity_map] ||= Hash.new { |h,k| h[k] = {} }
      end

      def use
        old, self.enabled = enabled, true

        yield if block_given?
      ensure
        self.enabled = old
        clear
      end

      def without
        old, self.enabled = enabled, false

        yield if block_given?
      ensure
        self.enabled = old
      end

      def get(klass, primary_key)
        record = repository[klass.symbolized_sti_name][primary_key]

        if record.is_a?(klass)
          klass.connection.log_info("#{klass} (id: #{primary_key})", "IdentityMap Load", 0.0)
          record
        else
          nil
        end
      end

      def add(record)
        repository[record.class.symbolized_sti_name][record.id] = record
      end

      def remove(record)
        repository[record.class.symbolized_sti_name].delete(record.id)
      end

      def remove_by_id(symbolized_sti_name, id)
        repository[symbolized_sti_name].delete(id)
      end

      def clear
        repository.clear
      end
    end
  end
end
