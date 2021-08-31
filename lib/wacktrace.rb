# frozen_string_literal: true

require_relative "wacktrace/version"

module Wacktrace
  class Error < StandardError; end
  class << self
    def add_to_stack(lines, &real)
      if lines.length <= 0
        return real.call
      end
      lines = fix_duplicate_methods(lines)

      # Create a namespace for all these methods so we don't polute the global
      # namespace.
      container_class = Class.new
    
      raise "add to stack missing block" unless block_given?
    
      # puts lines
      # replace spaces with non-breaking spaces
      lines = lines.map { |line| [clean_method_name(line[0]), line[1], line[2]] }
    
      # Define each method in series: a calls b, b calls c, and so on.  The last
      # line does not get a method defined here.
      lines.each_cons(2) do |line_1, line_2|
        # puts "defining '#{line_1[0]}'"
        success = true
        define_stack_level(container_class, line_1, line_2[0])
      end
    
      last = lines.last
      define_stack_level(container_class, last, 'ending')
      container_class.define_singleton_method("ending") { real.call }
      return container_class.send(lines.first[0])
    end

    private

    # Because we can't have two methods with the same name in the same
    # namespace, we'll need to modify any lines with the same method name
    # (line[0]).  To do this, we'll just pad each duplicate line with
    # non-breaking spaces.  So if you have several lines with the method name
    # "foo", they'll become "foo", "foo ", "foo  ", etc.
    def fix_duplicate_methods(lines)
      counts = {}
      lines.map { |line|
        method_name = line[0]
        if counts[method_name]
          original_method_name = method_name
          method_name = method_name + (' ' * counts[method_name])
          counts[original_method_name] += 1
        else
          counts[method_name] = 1
        end
        [method_name, line[1], line[2]]
      }
    end

    def clean_method_name(string)
      # Always start the method name with a non-breaking space so ruby doesn't
      # interpret it as a constant if you started the string with a capital.
      ' ' + string
        .gsub(' ', ' ')
        .gsub(',', '，')
        .gsub('.', '․')
        .gsub(':', '：')
        .gsub("'", '’')
        .gsub("@", '＠')
        .gsub("`", '`')
        .gsub("~", '～')
        .gsub("#", '＃')
        .gsub("$", '＄')
        .gsub("%", '％')
        .gsub("^", '＾')
        .gsub("&", '&')
        .gsub("*", '＊')
        .gsub("(", '（')
        .gsub(")", '）')
        .gsub("-", '–')
        .gsub("+", '＋')
        .gsub("[", '［')
        .gsub("]", '］')
        .gsub("|", '｜')
        .gsub("/", '／')
        .gsub('\\', '＼')
        .gsub(";", ';')
        .gsub("{", '｛')
        .gsub("}", '｝')
        .gsub("\"", '＂')
        .gsub("'", '＇')
        .gsub("<", '＜')
        .gsub(">", '＞')
        # These are technically allowed at the end of a method, but I'm too lazy to
        # write logic to allow that.
        .gsub('!', '︕')
        .gsub('?', '︖')
        .gsub('=', '＝')
    end

    # Calls the given block with the given "lines" inserted into the call stack.
    # Each line should look like:
    #
    #  [ "somemethodname", 123, "somefilename"]
    #
    # which will result in a traceback line that looks like:
    #
    #  3: from somemethodname:123:in `somefilename'
    #
    def define_stack_level(container_class, line, body)
      success = true

      # For some reason line numbers come out as one higher than whatever we put in here.
      line_number = line[1].to_i - 1
      method_name = line[0]
      file_name = line[2]

      method_string = "def #{method_name}\n#{body}\nend"

      begin
        container_class.instance_eval(method_string, file_name, line_number)
      rescue SyntaxError => e
        success = false
      end

      if !success || !container_class.methods.include?(method_name.to_sym)
        warn("
          Unable to create a method named:
          #{method_name}
          with body
          #{method_string}
          One of them probably contains some special character that's not yet handled."
        )
      end
    end

    def lyrics_to_stack_lines(lyrics)
      # file = "Percy Bysshe Shelley"
      file = "⚠️"
      # TODO: deal with duplicate lines
      lyrics.split("\n").map.with_index do |line, i|
        [line, i, file]
      end
    end
    
    def add_lines_to_stack(lines, &real)
      add_to_stack(lyrics_to_stack_lines(lines), &real)
    end
  end
end