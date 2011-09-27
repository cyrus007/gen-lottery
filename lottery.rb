# myapp.rb
require 'rubygems' if RUBY_VERSION < '1.9'
require 'sinatra'
require 'faster_csv'
require 'google_visualr'

#  Add methods to Enumerable, which makes them available to Array
module Enumerable
 
  #  sum of an array of numbers
  def sum
    return self.inject(0){|acc,i|acc +i}
  end
 
  #  average of an array of numbers
  def average
    return self.sum/self.length.to_f
  end
 
  #  variance of an array of numbers
  def sample_variance
    avg=self.average
    sum=self.inject(0){|acc,i|acc +(i-avg)**2}
    return(1/self.length.to_f*sum)
  end
 
  #  standard deviation of an array of numbers
  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end
 
end  #  module Enumerable

class Lottery
  attr_accessor :data
  def initialize(file)
    @data = []
    FasterCSV.foreach(file, :quote_char => '"', :col_sep => ',', :row_sep => :auto) do |row|
      @data << [ Date::civil( row[3].to_i, row[1].to_i, row[2].to_i), row[4], row[5], row[6], row[7], row[8], row[9], row[10] ]
    end
  end

  def prev_match
    bucket = []
    @data.each do |cell|
      bucket << [ cell[0], [cell[1].to_i, cell[2].to_i, cell[3].to_i, cell[4].to_i, cell[5].to_i ].sort.to_s ]
    end
    bucket
    me = @data[@data.length - 2]
    mystr = [me[1].to_i, me[2].to_i, me[3].to_i, me[4].to_i, me[5].to_i].sort.to_s
    bucket.each_with_index do |val, i|
      if val[1] == mystr
p       i.to_s + ':Dates ' + val[0].to_s + '|' + me[0].to_s
      end
    end
  end

  def stack(from=nil, to=nil)
    from = Date.new(1991, 1, 1) if from.nil?
    to = Date.today if to.nil?
    interval = from..to
    stack = Array.new(56){|i| 0}
    @data.each do |cell|
#     next cell if cell[0] <= from || cell[0] > to
      next cell unless interval.include?(cell[0])
      stack[cell[1].to_i - 1] += 1
      stack[cell[2].to_i - 1] += 1
      stack[cell[3].to_i - 1] += 1
      stack[cell[4].to_i - 1] += 1
      stack[cell[5].to_i - 1] += 1
    end
    stack
  end
end

class Lotto < Lottery
  def stack(from=nil, to=nil)
    from = Date.new(1991, 1, 1) if from.nil?
    to = Date.today if to.nil?
    stack = super(from, to)
    @data.each do |cell|
      next cell if cell[0] <= from || cell[0] > to
      stack[cell[6].to_i - 1] += 1
    end
    stack
  end
end

class MMillion < Lottery
  def pball
    last = Array.new(56){|i| 0}
    @data.each do |cell|
      last[cell[6].to_i - 1] += 1
    end
    last
  end
end

get '/c5' do
    gdata = Lottery.new("cashfive.csv")
    gdata.prev_match
    from = Date.new(1991,1,1); to = Date.new(2010,1,1)
    ldata = gdata.stack(from, to)
    from = to; to = Date.new(2011,1,1)
    rdata = gdata.stack(from, to)
    from = to
    xdata = gdata.stack(from)
    lc5data = ldata[0..36]
    lc5data.each_index {|i| lc5data[i] = lc5data[i] - 400 }
    rc5data = rdata[0..36]
    xc5data = xdata[0..36]
    totaldata = Array.new(36){|i| 0}
#   lc5data.each_index {|i| totaldata[i] = lc5data[i] + rc5data[i] + xc5data[i] } 
#   totaldata
#   totaldata.standard_deviation
#   totaldata.average

    tabs = []
    lc5data.each_index {|i| tabs << { :c => [{:v => (i+1).to_s}, {:v => lc5data[i]}, {:v => rc5data[i]}, {:v => xc5data[i]}] } }
    data = { :cols => [{:type => :string, :label => 'No.'},
                       {:type => :number, :label => '< 2010.01.01'},
                       {:type => :number, :label => '< 2011.01.01'},
                       {:type => :number, :label => 'till Today'}],
             :rows => tabs }
    data_table = GoogleVisualr::DataTable.new(data)
    lc5data.each_index {|i| data_table.set_cell(i, 0, (i+1).to_s) }
    data_table.to_js
#   opts  = { :width => 800, :height => 400, :title => 'Cash Five', :isStacked => true, :hAxis => { :title => 'No.', :titleTextStyle => {:color => 'red'}} }
#   chart = GoogleVisualr::Interactive::ColumnChart.new(data_table, opts)
#   chart.to_js('cash')
end

get '/lt' do
    gdata = Lotto.new("lottotexas.csv")
    from = Date.new(2001,1,1); to = Date.new(2010,1,1)
    ldata = gdata.stack(from, to)
    from = to; to = Date.new(2011,1,1)
    rdata = gdata.stack(from, to)
    from = to
    xdata = gdata.stack(from)
    lltdata = ldata[0..53]
#   lltdata.each_index {|i| 
#     lltdata[i] -= 180 if i < 44
#     lltdata[i] -= 150 if i >= 44 && i < 50
#     lltdata[i] -= 50  if i >= 50 && i < 55
#   }
    rltdata = rdata[0..53]
    xltdata = xdata[0..53]
#   totaldata = Array.new(53){|i| 0}
#   lltdata.each_index {|i| totaldata[i] = lltdata[i] + rltdata[i] + xltdata[i] } 
#   totaldata
#   totaldata.standard_deviation
#   totaldata.average

    tabs = []
    lltdata.each_index {|i| tabs << { :c => [{:v => (i+1).to_s}, {:v => lltdata[i]}, {:v => rltdata[i]}, {:v => xltdata[i]}] } }
    data = { :cols => [{:type => :string, :label => 'No.'},
                       {:type => :number, :label => '< 2010.01.01'},
                       {:type => :number, :label => '< 2011.01.01'},
                       {:type => :number, :label => 'till Today'}],
             :rows => tabs }
    data_table = GoogleVisualr::DataTable.new(data)
    lltdata.each_index {|i| data_table.set_cell(i, 0, (i+1).to_s) }
    data_table.to_js
end

get '/mm' do
    gdata = MMillion.new("megamillions.csv")
    mmdata = gdata.stack
    pbdata = gdata.pball
    tabs = []
    mmdata.each_index {|i| tabs << { :c => [{:v => (i+1).to_s}, {:v => mmdata[i]}, {:v => pbdata[i]}] } }
    data = { :cols => [{:type => :string, :label => 'No.'},
                       {:type => :number, :label => 'Draws'},
                       {:type => :number, :label => 'PowerBall'}],
             :rows => tabs }
    data_table = GoogleVisualr::DataTable.new(data)
    mmdata.each_index {|i| data_table.set_cell(i, 0, (i+1).to_s) }
    data_table.to_js
end

post '/' do

end
