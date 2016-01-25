require 'pry'
class  New_l
  @@debug = false
  @@code = ''
  KEYWORDS = {
    '+' => :add,
    '-' => :sub,
    '*' => :mul,
    '/' => :div,
    '%' => :mod,
    '>=' => :less_or_equal,
    "<=" => :more_or_equal,
    '>' => :less,
    '<' => :more,
    '==' => :equal,
    '!=' => :not_equal,
    '=' => :assignment,
    '(' => :lpar,
    ')' => :rpar,
    'if' => :if,
    'elsif' => :elsif,
    'else' => :else,
    'while' => :while,
    'print' => :print,
    'def' => :def,
    '{' => :lblock,
    '}' => :rblock
  }

  @@in_block = false
  @@space = {}
  @@tokens = []
  @@def_tokens = {}
  @@def_args = {}

   def init
    @@file = open(ARGV[0], "r").read #ファイル読み込み
    @@file.each_line do |line|
      @@code += line
    end
    p @@code if @@debug
    result = sentences
    syntax_analysis result
  end

  def get_token(text = nil)
    temp = @@code
    temp = text if text
    p "get_tokenスタート" if @@debug
    if temp =~ /\A\s*(#{KEYWORDS.keys.map{|t| Regexp.escape(t)}.join('|')})/
      temp = $'
      p "演算子#{KEYWORDS[$1]}" if @@debug
      p "get_tokenおわり" if @@debug
      @@code = temp unless text
      return KEYWORDS[$1]
    elsif temp =~ /\A\s*([0-9.]+)/
      temp = $'
      p "数値#{$1.to_f}" if @@debug
      p "get_tokenおわり" if @@debug
      @@code = temp unless text
      return $1.to_f
    elsif temp =~ /\A\s*([a-zA-Z][a-zA-Z0-9_]*)/
      temp = $'
      p "変数#{$1}" if @@debug
      @@code = temp unless text
      return $1
    elsif temp =~ /\A\s*(\;)/
      temp = $'
      @@code = temp unless text
      return :sem
    elsif temp =~ /\A\s*\z/
      p "get_tokenがnilおわり" if @@debug
      return nil
    end
    p "get_tokenがbadおわり" if @@debug
    return :bad_token
  end

  def unget_token(token)
    p "unget_tokenスタート" if @@debug
    p "tokenは#{token}" if @@debug
    p "unget前のcodeは#{@@code}" if @@debug
    if token.is_a? Numeric
      @@code = token.to_s + @@code
    elsif KEYWORDS.key(token)
      @@code = KEYWORDS.key(token) + @@code
    elsif token
      @@code = token + @@code
    end
    p "unget後のcodeは#{@@code}" if @@debug
    p "unget_tokenおわり" if @@debug
  end

  def sentences
    unless s = sentence
      raise Exception, "やばす"
    end
    result = [:block, s]
    while s = sentence
      unless s
        return result
      end
      result << s
    end
    return result
  end

  def sentence
    token = get_token
    if @@in_block
      if token == :rblock
        @@in_block = false
        return nil
      end
    end
    case token
    when :def
      return def_process
    when :print
      return print_process
    when :if
      return if_process
    when :while
      return while_process
    else
      op = get_token
      case op
      when :assignment
        p @@in_block  if @@debug
        return [:assignment, token, expression]
      when :lpar
        return [:execute, token, args_parser]
      end
    end
  end

  def def_process
    name = get_token
    args = args_parser
    lines = block_parser
    result = [:def, name, args, lines]
    @@def_tokens[name] = [args,lines]
    return result
  end

  def print_process
    return [:print, expression]
  end

  def while_process
    cond = condition_parser
    lines = block_parser
    return [:while, cond, lines]
  end

  def if_process
    cond = condition_parser
    lines = block_parser
    result = [:if, cond, lines]
    token = get_token
    while (token == :elsif) do
      result << token
      result << condition_parser
      result << block_parser
      token = get_token
    end
    if (token == :else)
      result << token
      result << block_parser
    else
      unget_token token
    end
    return result
  end

  def args_parser
    @@code =~ /\A\s*\((.*?)\)/
    return nil unless :lpar == get_token
    token = get_token
    @@code = $'
    return token
  end

  def condition_parser
    @@code =~ /\A\s*\((.*?)\)/
    result = []
    unless :lpar == get_token
      return nil
    end
    right = get_token
    op = get_token
    left = get_token
    @@code = $'
    return [op, right, left]
  end

  def block_parser
    @@code =~ /\A\s*\{.*?\}/
    if :lblock == get_token
      @@in_block = true
      lines = sentences
      return lines
    end
  end

  def expression
    p "expressionスタート" if @@debug
    result = term
    while true
      token = get_token
      unless token == :add or token == :sub
        unget_token token
        break
      end
      result = [token, result, term]
    end
    p "expressionおわり" if @@debug
    return result
  end

  def term
    p "termスタート" if @@debug
    result = factor
    while true
      token = get_token
      unless token == :mul or token == :div
        unget_token token
        break
      end
      result = [token, result, factor]
    end
    p "term終わり" if @@debug
    return result
  end

  def factor
    p "factorスタート" if @@debug
    token = get_token
    minusflg = 1
    if token == :sub
      minusflg = -1
      token = get_token
    end
    if token.is_a? Numeric
      p "factorおわり" if @@debug
      return token * minusflg
    elsif token.is_a? String
      return token
    elsif token == :lpar
      result = expression
      unless get_token == :rpar
        raise Exception, "unexpected token"
      end
      p "factorおわり" if @@debug
      return [:mul, minusflg, result]
    else
      raise Exception, "unexpected token"
    end
  end

  def syntax_analysis result
    p @@def_tokens if @@debug
    p result if @@debug
    i = 0
    while i < result.size do
      eval result[i]
      i += 1
    end
    p @@space if @@debug
  end

  def eval(ast)
    p "evalスタート" if @@debug
    if ast.instance_of? Array
      p ast if @@debug
      case ast[0]
      when :block, :def
        eval(ast[1])
      when :assignment
        @@space[(ast[1])] = eval(ast[2])
      when :if, :elsif
        if condition_eval ast[1]
          eval(ast[2])
        else

        end
      when :else
        eval(ast[1])
      when :print
        p eval(ast[1])
      when :while
        while condition_eval ast[1] do
          syntax_analysis(ast[2])
        end
      when :execute
        @@def_args[@@def_tokens[ast[1]][0]] = eval(ast[2])
        syntax_analysis(@@def_tokens[ast[1]][1])
        @@def_args = {}
      when :add
        return eval(ast[1]) + eval(ast[2])
      when :sub
        p "evalおわり" if @@debug
        return eval(ast[1]) - eval(ast[2])
      when :mul
        p "evalおわり" if @@debug
        return eval(ast[1]) * eval(ast[2])
      when :div
        p "evalおわり" if @@debug
        return eval(ast[1]) / eval(ast[2])
      end
    else
      if ast.is_a? Numeric
        p "evalおわり" if @@debug
        return ast.to_f
      elsif ast.is_a? String
        if @@space.keys.include? ast
          return @@space[ast].to_f
        elsif @@def_args.keys.include? ast
          return @@def_args[ast].to_f
        else
          return ast
        end
      end
    end
  end

  def condition_eval cond
    case cond[0]
    when :equal
      if(eval(cond[1]) == eval(cond[2]))
        return true
      end
    when :more
      if (eval(cond[1]) < eval(cond[2]))
        return true
      end
    when :more_or_equal
      if (eval(cond[1]) <= eval(cond[2]))
        return true
      end
    when :less
      if (eval(cond[1]) > eval(cond[2]))
        return true
      end
    when :less_or_equal
      if (eval(cond[1]) >= eval(cond[2]))
        return true
      end
    end
    return false
  end

end

nl = New_l.new
nl.init
