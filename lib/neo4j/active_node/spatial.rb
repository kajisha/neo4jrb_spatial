module Neo4j::ActiveNode
  module Spatial
    def self.included(other)
      other.extend(ClassMethods)
    end

    def add_to_spatial_index(index_name = nil)
      index = index_name || self.class.spatial_index_name
      fail 'index name not found' unless index
      Neo4j::Session.current.add_node_to_spatial_index(index, self)
    end

    module ClassMethods
      attr_reader :spatial_index_name
      def spatial_index(index_name = nil)
        return spatial_index_name unless index_name
        # create_index_callback(index_name)
        @spatial_index_name = index_name
      end

      # This will not work for now. Neo4j Spatial's REST API doesn't seem to work within transactions.
      # def create_index_callback(index_name)
      #   after_create(proc { |node| Neo4j::Session.current.add_node_to_spatial_index(index_name, node) })
      # end

      # private :create_index_callback

      def spatial_match(var, params_string)
        fail 'Cannot query without index. Set index in model or as third argument.' unless spatial_index_name

        query = Neo4j::Core::Query.new.start("#{var} = node:#{spatial_index_name}('#{params_string}')") & current_scope.query

        query.proxy_as(self, var)
      end
    end
  end

  module Scope
    class ScopeEvalContext
      module_eval %{
        def spatial_match(*args)
          @target.all.scoping do
            (@query_proxy || @target).spatial_match(*args)
          end
        end
      }, __FILE__, __LINE__ + 1
    end
  end
end
