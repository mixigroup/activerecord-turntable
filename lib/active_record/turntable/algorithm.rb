module ActiveRecord::Turntable
  module Algorithm
    autoload :Base, "active_record/turntable/algorithm/base"
    autoload :RangeAlgorithm, "active_record/turntable/algorithm/range_algorithm"
    autoload :RangeBsearchAlgorithm, "active_record/turntable/algorithm/range_bsearch_algorithm"
    autoload :ModuloAlgorithm, "active_record/turntable/algorithm/modulo_algorithm"
  end
end
