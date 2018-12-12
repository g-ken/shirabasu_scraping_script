require 'nokogiri'
require 'open-uri'
require 'csv'
require 'uri'
require 'benchmark'

def get_school
  #puts %(starting get_school_id)
  uri = "https://syllabus.kosen-k.go.jp/Pages/PublicSchools"

  charset = nil

  html = open(uri) do |f|
    charset = f.charset
    f.read
  end

  doc = Nokogiri::HTML.parse(html, nil, charset)
  doc.xpath('//div[@style=""]/div[@class="btn btn-default"]').each do |node|
    node.css('a').each do |link|
      school_id = link[:href][35,2]
      uri = "https://syllabus.kosen-k.go.jp" + link[:href]
      #puts %(getting #{uri})
      get_department_id(uri, school_id)
    end
  end
end

def get_department_id(uri, school_id)
  #puts %(getting department_id)
  charset = nil

  department_name = String.new
  department_id = String.new 

  html = open(uri) do |f|
    charset = f.charset
    f.read
  end

  doc = Nokogiri::HTML.parse(html, nil, charset)
  file_name = doc.at('//h1').inner_text
  doc.xpath('//body/div/div/div[@class="row"]/div/div[@class="panel panel-default"]/div[@class="panel-body"]/div/div[@class="row"]/div[@class="col-md-6"]').each do |node|
    if node.xpath('h4[@class="list-group-item-heading"]').inner_text.empty?
      next
    else
      department_name = node.xpath('h4[@class="list-group-item-heading"]').inner_text
    end
    node.parent.css('a').each do |link|

      if link[:href].include?("Subjects")
        uri= "https://syllabus.kosen-k.go.jp" + link[:href]
        #puts %(getting #{uri})
        get_subject_code(uri, file_name)
      else
        next
      end
    end
  end
end

def get_subject_code(uri, file_name)
  %(getting subjct code)

  charset = nil

  titles = []

  html = open(uri) do |f|
    charset = f.charset
    f.read
  end

  doc = Nokogiri::HTML.parse(html, nil, charset)
  file_name += ("_" + doc.at('//h1').inner_text)
  doc.xpath('//tr[@class="course- "]/td').each do |node|
    node.xpath('div[@class="subject-item"]').each do |child_node|
      child_node.css('a').each do |link|
        uri = URI.encode("https://syllabus.kosen-k.go.jp" + (link[:href].gsub(/\\u([\da-fA-F]{4})/) { [$1].pack('H*').unpack('n*').pack('U*') }))
        get_bg_success(uri, file_name)
      end
    end
  end
end

def get_bg_success(uri,file_name)
  #puts %(getting bg duccess)
  charset = nil

  html = open(uri) do |f|
    charset = f.charset
    f.read
  end

  row = Array.new(2)
  column = Array.new(1)
  subject_title = Array.new
  doc = Nokogiri::HTML.parse(html, nil, charset)
  doc.xpath('//table[@id="MainContent_SubjectSyllabus_wariaiTable"]').each do |node|
    node.xpath('tr[@class="bg-success"]/th').each do |child_node|
      row << child_node.inner_text
    end
    node.xpath('tr[not(@*)]/th').each do |child_node|
      column << child_node.inner_text
    end
  end

  table = Array.new(column.count).map{Array.new(row.count+2, nil)}
  subject_title = doc.at('//h1').inner_text
  doc.xpath('//table[@id="MainContent_SubjectSyllabus_wariaiTable"]').each_with_index do |node, i|
    node.xpath('tr[not(@*)]').each.with_index(0) do |child_node, j|
      child_node.xpath('*').each.with_index(1) do |grandson_node, k|
        table[j][k] = grandson_node.inner_text
      end
    end
  end
  #puts file_name
  CSV.open("./shirabasu/#{file_name}.csv", "a") do |csv|
    csv << [subject_title]
    csv << row
    table.each do |chile_table|
      csv << chile_table
    end
    csv << []
  end
end

Benchmark.bm do |bm|
  bm.report { get_school }
end

#get_subject_code("https://syllabus.kosen-k.go.jp/Pages/PublicSubjects?school_id=40&department_id=13&year=2018", "test")

#puts URI.encode("https://syllabus.kosen-k.go.jp" + ("/Pages/PublicSyllabus?school_id=40&department_id=13&subject_code=104610（後期）&year=2018".gsub(/\\u([\da-fA-F]{4})/) { [$1].pack('H*').unpack('n*').pack('U*') }))