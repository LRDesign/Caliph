module Caliph
  class Describer
    attr_accessor :apex

    def initialize(apex)
      @apex = apex
    end

    def describe(&block)
      apex.definition_watcher = self
      yield apex
      return apex
    end

    def inspect
      "Watcher@#{"%#0x" % apex.object_id}"
    end
  end
end
