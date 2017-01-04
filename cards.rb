S={:s=>"\u2660",:c=>"\u2663",:h=>"\u2665",:d=>"\u2666"}
V=Regexp.new(/(?<s>(#{S[:s]}|#{S[:c]}|#{S[:h]}|#{S[:d]}|A|B))(?<v>(\d\d?|[AJQKX]))/)
M={S[:c]=>0,S[:d]=>13,S[:h]=>26,S[:s]=>39,"A"=>1,"J"=>11,"Q"=>12,"K"=>13}
I={1=>"A",11=>"J",12=>"Q",13=>"K"}
def i2c(i)
  if i > M[S[:c]] then s = :c end
  if i > M[S[:d]] then s = :d end
  if i > M[S[:h]] then s = :h end
  if i > M[S[:s]] then s = :s end
  i -= M[S[s]]
  v = (I.key?(i) ? I[i] : i)
  "#{S[s]}#{v}"
end
def c2i(c)
  V.match c do |m|
    if m["v"]=="X" then m["s"] else M[m["s"]]+(M.key?(m["v"])?M[m["v"]]:m["v"].to_i)
    end
  end
end
def prp(i)
  d = i.split /\s+/
  if d.length!=54 then raise("Bad d") end
  d.collect {|c| c2i c}
end
def md(d,c)
  i=d.find_index c
  if i!=53
    d[i],d[i + 1]=d[i+1],d[i]
    return d
  else
    return d.reverse.rotate.reverse
  end
end
def tc(d)
  f,l = d.find_index('A'),d.find_index('B')
  f,l=(f>l ? [l,f] : [f,l])
  a=d.shift f
  b=d.reverse!.shift(53-l)
  return b.reverse+d.reverse+a
end
def cc(d)
  if !d[-1].is_a? Integer then return d end
  l=d.pop
  f=d.shift(l)
  return d+f+[l]
end
def kc(d)
  v={'A'=>53,'B'=>54};
  c=v.key?(d[0]) ? d[0] : v[d[0]]
  d[c]
end
def ks1(d)
  d=md(d,'A')
  d=md(d,'B')
  d=md(d,'B')
  d=tc(d)
  d=cc(d)
  c=kc(d)
  if !c.is_a? Integer then c,d = ks1(d) end
  return c,d
end
def ks5(d)
  ks=Array.new(5,nil)
  ks[0],d = ks1 d
  ks[1],d = ks1 d
  ks[2],d = ks1 d
  ks[3],d = ks1 d
  ks[4],d = ks1 d
  return ks,d
end
def go(d,i,e)
  i=i.gsub(/[^a-zA-Z]/,'').upcase.split(/(.{5})/).reject {|e| e==""}
  i[-1]=i[-1].ljust(5,'X')
  i.collect! do |s|
    q=s.split(//);k,d=ks5 d
    q.collect! do |c|
      c=c.ord-64
      if e then c=(c+k.shift)%26 else c=(c-k.shift)%26 end
      (c+64).chr
    end
    q.join
  end
  puts i.join(' ')
end
def cr
  d = (1..52).to_a
  d.collect! {|i| i2c i}
  d += ['AX', 'BX']
  puts d.shuffle.join ' '
end
def gn
  print("d> ")
  d=prp(STDIN.gets.chomp)
  print "t> "
  text=STDIN.gets.chomp
  go d,text,ARGV.length>0
end
if ARGV[0]=="shuffle" cr;exit else gn;exit end
