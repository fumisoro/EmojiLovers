require "pry"
class Language
  @@tokens = []
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
    '=' => :insert,
    '==' => :equal,
    'int' => :int
  }
  @@space = {}
  @@line = []
  @@name = ""

  def init
    @@file = open(ARGV[0], "r").read #ファイル読み込み
    @@file.each_line do |line|
      @@code += line.chomp
    end
    lexical
  end

  def lexical
    while @@code != ""
      p "lexicalループ"
      a = parser
      @@tokens << a if a
      @@line = []
    end
    p "ここから"
    p @@tokens
  end

  def parser
    p "parserスタート"
    token = get_token
    p "parserのtokenは#{token}"
    case token
    when :int
      name = get_token
      value = expression
      return [token, name, value]
    when :if
      p "来ました"
      @@code =~ /\s*\((.*)(\)\s*\{)/
      condition = $1
      @@code = $'
      @@line << parser
      p "if文の最後には#{@@line}をいれる"
      return [token, condition, @@line]
    when :insert
      binding.pry
      return [token]
    end
  end

  def get_token
    p "get_tokenスタート"
    p @@code
    if @@code =~ /\A\s*(#{KEYWORDS.keys.map{|t| Regexp.escape(t)}.join('|')})/
      @@code = $'
      p "演算子#{KEYWORDS[$1]}"
      p "get_tokenおわり"
      return KEYWORDS[$1]
    elsif @@code =~ /\A\s*(\=\s*)(.+)/
      p "変数の中身来た"
      return expression
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
      p "変数名きた"
      p $1
      p "get_tokenおわり"
      return $1
    elsif @@code =~ /\A\s*(\;)/
      p "まっち！！"
      @@code = $'
      p "get_tokenおわり"
      return :end
    end
    p "get_tokenおわりbad"
    return :bad_token
  end

  def unget_token(token)
    p "unget_tokenスタート"
    p "tokenは#{token}"
    p "unget前のcodeは#{@@code}"
    if token.is_a? Numeric
      @@code = token.to_s + @@code
    else
      @@code = KEYWORDS.index(token) ? KEYWORDS.index(token) + @@code : @@code
    end
    p "unget後のcodeは#{@@code}"
    p "unget_tokenおわり"
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
    p "result "+ result.to_s
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
    p token
    minusflg = 1
    if token == :sub
      minusflg = -1
      token = get_token
    end
    if token == :insert
      return expression
    end
    if token == :end
      return token
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
      result = parser
      unless get_token == :rblock
        raise Exception, "unexpected token"
      end
    else
      raise Exception, "unexpected token"
    end
  end
end
l = Language.new
l.init