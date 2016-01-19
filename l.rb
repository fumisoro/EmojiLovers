require 'pry'
class L
  @@tokens = []
  @@code =""
  @@tmp
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
    'int' => :int
  }

  EX_KEYWORDS = {
    '==' => :equal,
    '=' => :insert,
    '+' => :add,
    '-' => :sub,
    '*' => :mul,
    '/' => :div,
    '%' => :mod
  }

  def init
    @@file = open(ARGV[0], "r").read #ファイル読み込み
    @@file.each_line do |line|
      @@code += line.chomp
    end
    parser
  end

  def parser
    while true
      if @@code =~ /\A\s*(if)\s*\((.+)\)/
        @@tokens << $1
        @@tokens << "("
        p $2
        a = ex_parser $2
        a.each do |v|
          @@tokens << v
        end
        @@tokens << ")"
        p @@tokens
      elsif @@code =~ /\A\s*\{(.+)\}/
        @@tokens << "{"
        tmp = []
        p $1
        a = block_parser $1
        a.each do |v|
          @@tokens << v
        end
        @@tokens << "}"
        p @@tokens
      elsif @@code =~ /\A\s*def\((.*)\)\{(.*)\}/

      end
      @@code = $'
      break if @@code == ""
    end
  end

  def ex_parser(ex, tmp = [])
    if ex =~ /\A\s*([a-zA-Z][a-zA-Z0-9]*)/
    elsif ex =~ /\A\s*(#{EX_KEYWORDS.keys.map{|t| Regexp.escape(t)}.join('|')})/
    elsif ex =~ /\A\s*([0-9.]+)/
    end
    tmp << $1
    ex = $'
    ex_parser(ex, tmp) if ex != ""
    return tmp
  end

  def block_parser(block, tmp = [])
    binding.pry
    p block
    if block =~ /\A\s*([a-zA-Z][a-zA-Z0-9]*)/
      p "まじか"
    elsif block =~ /\A\s*(#{EX_KEYWORDS.keys.map{|t| Regexp.escape(t)}.join('|')})/
      p "はい"
    elsif block =~ /\A\s*([0-9.]+)/
      p "ほい"
    elsif block =~ /(\;)/
    end
    tmp << $1
    block = $'
    block_parser(block, tmp) if block != ""
    return tmp
  end

end

l = L.new
l.init