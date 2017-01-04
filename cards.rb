S={:s=>"\u2660",:c=>"\u2663",:h=>"\u2665",:d=>"\u2666"}
V=Regexp.new(/(?<s>(#{S[:s]}|#{S[:c]}|#{S[:h]}|#{S[:d]}|A|B))(?<v>(\d\d?|[AJQKX]))/)
M={S[:c]=>0,S[:d]=>13,S[:h]=>26,S[:s]=>39,"A"=>1,"J"=>11,"Q"=>12,"K"=>13}
I={1=>"A",11=>"J",12=>"Q",13=>"K"}
def i2c(i)
  s=:c if i>M[S[:c]]
  s=:d if i>M[S[:d]]
  s=:h if i>M[S[:h]]
  s=:s if i>M[S[:s]]
  i-=M[S[s]]
  v=(I.key?(i) ? I[i] : i)
  "#{S[s]}#{v}"
end
def c2i(c)
  V.match c do |m|
    if m["v"]=="X" then m["s"] else M[m["s"]]+(M.key?(m["v"])?M[m["v"]]:m["v"].to_i)
    end
  end
end
def pr(i)
  d = i.split /\s+/
  raise("Bad d") if d.length!=54
  d.collect {|c| c2i c}
end
def md(d,c)
  i=d.index c
  if i!=53
    d[i],d[i + 1]=d[i+1],d[i]
    return d
  else
    return [d[-1]]+d[0...-1]
  end
end
def tc(d)
  f,l = d.index('A'),d.index('B')
  f,l=l,f if f>l
  return [d[(l+1)..-1],d[f..l],d[0...f]].flatten
end
def cc(d)
  return d if d[-1].is_a? String
  l=d.pop
  f=d.shift(l-1)
  return d+f+[l]
end
def ks(d)
  d=md(d,'A')
  d=md(d,'B')
  d=md(d,'B')
  d=tc(d)
  d=cc(d)
  c=d[d[0].is_a?(Integer) ? d[0] : 53]
  c,d = ks(d) if c.is_a? String
  return c%26,d
end
def mod(c)
  return c-26 if c>26
  return c+26 if c<1
  return c
end
def go(d,i,e)
  i=i.gsub(/[^a-zA-Z]/,'').upcase
  i=i.ljust((i.length/5+1)*5, 'X') if i.length%5!=0
  o = ""
  i.each_byte do |c|
    k,d=ks d
    if e then n=(c-64+k)%26 else n=(c-64-k)%26 end
    n=26 if n==0
    o<<(n+64).chr
  end
  puts o.split(/(.{5})/).reject {|e| e==''}.join(' ')
end
def cr
  d=(1..52).to_a
  d.collect! {|i| i2c i}
  d+=['AX','BX']
  puts d.shuffle.join ' '
end
def gn
  print("d> ")
  d=pr(STDIN.gets.chomp)
  print "t> "
  text=STDIN.gets.chomp
  go d,text,ARGV.length>0
end
if ARGV[0]=="shuffle" then cr;exit else gn;exit end
