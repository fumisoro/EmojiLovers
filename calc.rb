class  Calc
  $code = ''
  $keywords = {
    '+' => :add,
    '-' => :sub,
    '*' => :mul,
    '/' => :div,
    '%' => :mod,
    '(' => :lpar,
    ')' => :rpar
  }

   #式 := 項 (('+'|'-')項)*
   #項 := 因子 (('*'|'/')因子)*
   #因子 := '-' ? (リテラル| '(' 式 ')')

  def get_token
    p "get_tokenスタート"
    p "#{$keywords.keys.map{|t| Regexp.escape(t)}.join('|')}"
    if $code =~ /\A\s*(#{$keywords.keys.map{|t| Regexp.escape(t)}.join('|')})/
      $code = $'
      p "演算子#{$keywords[$1]}"
      p "get_tokenおわり"
      return $keywords[$1]
    elsif $code =~ /\A\s*([0-9.]+)/
      $code = $'
      p "数値#{$1.to_f}"
      p "get_tokenおわり"
      return $1.to_f
    elsif $code =~ /\A\s*\z/
      p "get_tokenおわり"
      return nil
    end
    p "get_tokenおわり"
    return :bad_token
  end

  def unget_token(token)
    p "unget_tokenスタート"
    p "tokenは#{token}"
    p "unget前のcodeは#{$code}"
    if token.is_a? Numeric
      $code = token.to_s + $code
    else
      $code = $keywords.index(token) ? $keywords.index(token) + $code : $code
    end
    p "unget後のcodeは#{$code}"
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
    p "resultは#{result}"
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
    minusflg = 1
    if token == :sub
      minusflg = -1
      tokne = get_token
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

  def init
    loop {
      print 'exp> '
      $code = STDIN.gets # read
      exit 0 if $code == "quit\n"
      ex = expression #eval
      p ex
      p eval ex #print
    }
  end
end

cl = Calc.new
cl.init

