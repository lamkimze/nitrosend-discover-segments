module Segmentation
  class Provider
    def analyse(profiles)
      raise NotImplementedError, "#{self.class}#analyse must be implemented"
    end
  end
end
