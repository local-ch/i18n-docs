# encoding: utf-8

module I18nDocs
  class Utils

    # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/object/blank.rb
    def self.blank?(object)
      case object.class
      when Object
        object.respond_to?(:empty?) ? !!object.empty? : !object
      when NilClass
        true
      when FalseClass
        true
      when TrueClass
        false
      when String
        /\A[[:space:]]*\z/ === object
      when Hash, Array
        object.empty?
      when Numeric
        false
      else
        raise "Class not found"
      end
    end

    def self.present?(object)
      !blank?(object)
    end

    # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/inflector/methods.rb#L125
    def self.humanize(lower_case_and_underscored_word, options = {})
      result = lower_case_and_underscored_word.to_s.dup

      result.sub!(/\A_+/, '')
      result.sub!(/_id\z/, '')
      result.tr!('_', ' ')

      result.gsub!(/([a-z\d]*)/i) do |match|
        "#{match.downcase}"
      end

      if options.fetch(:capitalize, true)
        result.sub!(/\A\w/) { |match| match.upcase }
      end

      result
    end

  end
end