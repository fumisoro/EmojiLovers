require 'pry'
class  New_l
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
    'while' => :while,
    'print' => :print,
    'def' => :def,
    '{' => :lblock,
    '}' => :rblock
  }


  @@in_block = false
  @@space = {}
  @@tokens = []
   #式 := 項 (('+'|'-')項)*
   #項 := 因子 (('*'|'/')因子)*
   #因子 := '-' ? (リテラル| '(' 式 ')')

   def init
    @@file = open(ARGV[0], "r").read #ファイル読み込み
    @@file.each_line do |line|
      @@code += line
    end
    result = sentences
    syntax_analysis result
  end

  def get_token(text = nil)
    temp = @@code
    temp = text if text
    p "get_tokenスタート"
    p temp if text
    if temp =~ /\A\s*(#{KEYWORDS.keys.map{|t| Regexp.escape(t)}.join('|')})/
      temp = $'
      p "演算子#{KEYWORDS[$1]}"
      p "get_tokenおわり"
      @@code = temp unless text
      return KEYWORDS[$1]
    elsif temp =~ /\A\s*([0-9.]+)/
      temp = $'
      p "数値#{$1.to_f}"
      p "get_tokenおわり"
      @@code = temp unless text
      return $1.to_f
    elsif temp =~ /\A\s*([a-zA-Z][a-zA-Z0-9_]*)/
      temp = $'
      p "変数#{$1}"
      @@code = temp unless text
      return $1
    elsif temp =~ /\A\s*(\;)/
      temp = $'
      @@code = temp unless text
      return :sem
    elsif temp =~ /\A\s*\z/
      p "get_tokenがnilおわり"
      return nil
    end
    p "get_tokenがbadおわり"
    return :bad_token
  end

  def unget_token(token)
    p "unget_tokenスタート"
    p "tokenは#{token}"
    p "unget前のcodeは#{@@code}"
    if token.is_a? Numeric
      @@code = token.to_s + @@code
    elsif KEYWORDS.key(token)
      @@code = KEYWORDS.key(token) + @@code
    elsif token
      @@code = token + @@code
    end
    p "unget後のcodeは#{@@code}"
    p "unget_tokenおわり"
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
        p @@in_block
        return [:assignment, token, expression]
      end
    end
  end

  def def_process
    name = get_token
    arg = arg_parser
    lines = block_parser
    return [:def, name, arg, lines]
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
      result << :elsif
      result << condition_parser
      result << block_parser
      token = get_token
    end
    unget_token token
    return result
  end

  def arg_parser
    @@code =~ /\A\s*\((.*?)\)/
    @@code = $'
    return $1
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
      binding.pry
      return lines
    end
  end

  def expression
    p "expressionスタート"
    result = term
    while true
      token = get_token
      unless token == :add or token == :sub
        unget_token token
        break
      end
      result = [token, result, term]
    end
    p "expressionおわり"
    return result
  end

  def term
    p "termスタート"
    result = factor
    while true
      token = get_token
      unless token == :mul or token == :div
        unget_token token
        break
      end
      result = [token, result, factor]
    end
    p "term終わり"
    return result
  end

  def factor
    p "factorスタート"
    token = get_token
    minusflg = 1
    if token == :sub
      minusflg = -1
      token = get_token
    end
    if token.is_a? Numeric
      p "factorおわり"
      return token * minusflg
    elsif token.is_a? String
      return token
    elsif token == :lpar
      result = expression
      unless get_token == :rpar
        raise Exception, "unexpected token"
      end
      p "factorおわり"
      return [:mul, minusflg, result]
    else
      raise Exception, "unexpected token"
    end
  end

  def syntax_analysis result
    p result
    i = 0
    while i < result.size do
      eval result[i]
      i += 1
    end
  end

  def eval(ast)
    p "evalスタート"
    if ast.instance_of? Array
      p ast.size.to_s + "だよーん"
      case ast[0]
      when :block
        eval(ast[1])
      when :assignment
        @@space[(ast[1])] = eval(ast[2])
        p @@space
        binding.pry
      when :if

      when :add
        return eval(ast[1]) + eval(ast[2])
      when :sub
        p "evalおわり"
        return eval(ast[1]) - eval(ast[2])
      when :mul
        p "evalおわり"
        return eval(ast[1]) * eval(ast[2])
      when :div
        p "evalおわり"
        return eval(ast[1]) / eval(ast[2])
      end
    else
      if ast.is_a? Numeric
        p "evalおわり"
        return ast
      elsif ast.is_a? String
        binding.pry
        if @@space.keys.include? ast
          return @@space[ast].to_f
        else
          return ast
        end
      end
    end
  end
end

nl = New_l.new
nl.init

