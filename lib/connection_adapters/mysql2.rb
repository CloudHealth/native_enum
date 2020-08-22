require 'active_record/connection_adapters/mysql2_adapter'

module ActiveRecord
  module ConnectionAdapters

    # To support activerecord-mysql-awesome used in cloudpercept using Rails 4.2, we want to use AbstractMySqlAdapter. 
    # Its safe to do so: https://github.com/iangreenleaf/native_enum/pull/9  
    # This in theory can be done until when its not feasible anymore ie AR 6 when Mysql2Adapter has to be used
    # and by that point active-record-mysql-awesome should be long gone and we can use a prestine version
    # of native_enum moving forward...ie update your gemfile accordingly  
    # We want to use AbstractMySqlAdapter because this has been correctly monkey patched by activerecord-mysql-awesome into include
    # the appropriate enhancements from AR 5.0 backported to 4.x
    puts '** native_enum: activerecord-mysql-awesome is no longer required in Rails 5. Please remove it, and also use a new, unpatched version of native_enum from https://github.com/iangreenleaf/native_enum to remove this message **' if ActiveRecord::VERSION::MAJOR > 4
    can_use_abstract_adapter = ActiveRecord::VERSION::MAJOR > 3 && ActiveRecord::VERSION::MAJOR < 6
    use_preferable_adapter = defined?(Mysql2Adapter) ? Mysql2Adapter : AbstractMysqlAdapter
    existing_class = can_use_abstract_adapter ? AbstractMysqlAdapter : use_preferable_adapter

    existing_class.class_eval do
      def native_database_types_with_enum
        native_database_types_without_enum.merge({
          :enum => { :name => "enum" },
          :set => { :name => "set" }
        })
      end
      alias_method :native_database_types_without_enum, :native_database_types
      alias_method :native_database_types, :native_database_types_with_enum



      if ActiveRecord::VERSION::MAJOR >= 5 && ActiveRecord::VERSION::MINOR >= 1
        def type_to_sql_with_enum(type, limit: nil, **args)
          if type.to_s == "enum" || type.to_s == "set"
            list = limit
            if limit.is_a?(Hash)
              list = limit[:limit]
            end
            "#{type}(#{quoted_comma_list(list)})"
          else
            type_to_sql_without_enum(type, limit: limit, **args)
          end
        end
      else
        def type_to_sql_with_enum(type, limit=nil, *args)
          if type.to_s == "enum" || type.to_s == "set"
            list = limit
            if limit.is_a?(Hash)
              list = limit[:limit]
            end
            "#{type}(#{quoted_comma_list(list)})"
          else
            type_to_sql_without_enum(type, limit, *args)
          end
        end
      end
      alias_method :type_to_sql_without_enum, :type_to_sql
      alias_method :type_to_sql, :type_to_sql_with_enum

      private

      def quoted_comma_list list
        list.to_a.map{|n| "'#{n}'"}.join(",")
      end
    end
  end
end
