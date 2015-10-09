module ActiveFedora::Orders
  class ListNode
    attr_reader :rdf_subject
    attr_accessor :prev, :next, :target
    attr_writer :next_uri, :prev_uri
    attr_accessor :proxy_in, :proxy_for
    def initialize(node_cache, rdf_subject, graph=RDF::Graph.new)
      @rdf_subject = rdf_subject
      @graph = graph
      @node_cache = node_cache
      Builder.new(rdf_subject, graph).populate(self)
    end

    # Returns the next proxy or a tail sentinel.
    # @return [ActiveFedora::Orders::ListNode]
    def next
      @next ||=
        if next_uri
          node_cache.fetch(next_uri) do
            node = self.class.new(node_cache, next_uri, graph)
            node.prev = self
            node
          end
        end
    end

    # Returns the previous proxy or a head sentinel.
    # @return [ActiveFedora::Orders::ListNode]
    def prev
      @prev ||=
        if prev_uri
          node_cache.fetch(prev_uri) do
            node = self.class.new(node_cache, prev_uri, graph)
            node.next = self
            node
          end
        end
    end

    # Graph representation of node.
    # @return [ActiveFedora::Orders::ListNode::Resource]
    def to_graph
      g = Resource.new(rdf_subject)
      g.proxy_for = target.try(:uri)
      g.proxy_in = proxy_in.try(:uri)
      g.next = self.next.try(:rdf_subject)
      g.prev = self.prev.try(:rdf_subject)
      g
    end

    # Object representation of proxyFor
    # @return [ActiveFedora::Base]
    def target
      @target ||= 
        if proxy_for.present?
          node_cache.fetch(proxy_for) do
            ActiveFedora::Base.from_uri(proxy_for, nil)
          end
        end
    end

    # Persists target if it's been accessed or set.
    def save_target
      if @target
        @target.save
      else
        true
      end
    end


    # Methods necessary for association functionality
    def destroyed?
      false
    end

    def marked_for_destruction?
      false
    end

    def valid?
      true
    end

    def changed_for_autosave?
      true
    end

    def new_record?
      @target && @target.new_record?
    end

    private

    attr_reader :next_uri, :prev_uri, :graph, :node_cache

    class Builder
      attr_reader :uri, :graph
      def initialize(uri, graph)
        @uri = uri
        @graph = graph
      end

      def populate(instance)
        instance.proxy_for = resource.proxy_for.first
        instance.proxy_in = resource.proxy_in.first
        instance.next_uri = resource.next.first
        instance.prev_uri = resource.prev.first
      end

      private

      def resource
        @resource ||= Resource.new(uri, graph)
      end
    end

    class Resource < ActiveTriples::Resource
      property :proxy_for, predicate: ::RDF::Vocab::ORE.proxyFor, cast: false
      property :proxy_in, predicate: ::RDF::Vocab::ORE.proxyIn, cast: false
      property :next, predicate: ::RDF::Vocab::IANA.next, cast: false
      property :prev, predicate: ::RDF::Vocab::IANA.prev, cast: false
      def final_parent
        parent
      end
    end
  end
end