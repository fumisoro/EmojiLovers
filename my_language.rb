require 'scanf'
class My_language
  @@task = []
  @@code = ''
  KEYWORDS = {
    '+' => :add,
    '-' => :sub,
    '*' => :mul,
    '/' => :div,
    '%' => :mod,
    'if' => :if,
    'def' => :def,
    '(' => :lpar,
    ')' => :rpar,
    '{' => :lblock,
    '}' => :rblock,
    '==' => :equal,
    '=' => :insert,
    'int' => :int
  }
  @@space = {}
  @@tokens = []
  def init
    @@file = open(ARGV[0], "r").read #ファイル読み込み
    @@file.each_line do |line|
      @@code += line.chomp
    end
    lexical
  end

  def lexical
    while @@code != ""
      @@tokens << expression
    end
    p "ここから"
    p @@tokens

  end

  def get_token
    p "get_tokenスタート"
    p @@code
    if @@code =~ /\A\s*(#{KEYWORDS.keys.map{|t| Regexp.escape(t)}.join('|')})/
      @@code = $'
      p "演算子#{KEYWORDS[$1]}"
      p "get_tokenおわり"
      return KEYWORDS[$1]
    elsif @@code =~ /\A\s*([0-9.]+)/
      @@code = $'
      p "数値#{$1.to_f}"
      p "get_tokenおわり"
      return $1.to_f
    elsif @@code =~ /\A\s*\z/
      p "get_tokenおわりnil"
      return nil
    elsif @@code =~ /\A\s*([a-zA-Z][a-zA-Z0-9]*)/
      @@code = $'
      p "get_tokenおわり"
      return $1
    elsif @@code =~ /\A(\;)/
      p "まっち！！"
      @@code = $'
      p "get_tokenおわり"
      return :end
    end
    p "get_tokenおわりbad"
    return :bad_token
  end

  def unget_token(token)
    p "unget_tokenを#{token}でスタート"
    p "ungetしまっせ #{@@code}"
    if token.is_a? Numeric
      @@code = token.to_s + @@code
    else
      @@code = KEYWORDS.index(token) ? KEYWORDS.index(token) + @@code : @@code
    end
    p "ungetしましたぜ #{@@code}"
    p "unget_tokenおわり"
  end


  def expression
    p "解析開始！#{@@code}"
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
    @@task << result
    p "タスクは#{@@task}"
    return result
  end

  def term
    p "termスタート"
    result = factor
    while true
      token = get_token
      p "term内tokenは#{token}"
      unless token == :mul or token == :div or token == :insert
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
    puts "factor内tokenは#{token}"
    if token == :end
      expression
    end
    if token == :if
      return [token, expression]
    end
    if token == :insert
      return expression
    end
    if token.is_a? Numeric
      p "factorおわり"
      return token * minusflg
    elsif token == :lpar
      result = expression
      unless get_token == :rpar
        raise Exception, "unexpected token"
      end
      p "factorおわり"
      return [:mul, minusflg, result]
    elsif token == :lblock
      result = expression
      unless get_token == :rblock
        raise Exception, "unexpected token"
      end
    elsif token.is_a? String
      p "factorおわり"
      return token
    else
      raise Exception, "unexpected token"
    end
  end

  def eval(exp)
    p "evalスタート"
    if exp.instance_of? Array
      case exp[0]
      when :add
        p "evalおわり"
        return eval(exp[1]) + eval(exp[2])
      when :sub
        p "evalおわり"
        return eval(exp[1]) - eval(exp[2])
      when :mul
        p "evalおわり"
        return eval(exp[1]) * eval(exp[2])
      when :div
        p "evalおわり"
        return eval(exp[1]) / eval(exp[2])
      end
    else
      p "evalおわり"
      return exp
    end
  end


end

ml = My_language.new
ml.init