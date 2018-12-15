require 'nokogiri'
require 'open-uri'
require 'csv'
require 'uri'
require 'benchmark'
require 'typhoeus'

BASE_URL = "https://syllabus.kosen-k.go.jp"

def request_parsed_html(uri) #nokogiriでパースしたhtmlを返す
  charset = nil
  html = open(uri) do |f|
    charset = f.charset
    f.read
  end
  return Nokogiri::HTML.parse(html, nil, charset)
end

def get_school
  uri = "https://syllabus.kosen-k.go.jp/Pages/PublicSchools"
  doc = request_parsed_html(uri)

  doc.xpath('//div[not(@style="display:none")]/div[@class="btn btn-default"]').each do |node|
    node.css('a').each do |link|
      next_uri = BASE_URL + link[:href]
      get_department_id(next_uri)
    end
  end
end

def get_department_id(uri)
  puts uri
  department_name = String.new

  doc = request_parsed_html(uri)
  file_name = doc.at('//h1').inner_text

  doc.xpath('//div[@class="row"]/div[@class="col-md-6"]').each do |node|
    if node.xpath('h4[@class="list-group-item-heading"]').inner_text.empty?
      next
    else
      department_name = node.xpath('h4[@class="list-group-item-heading"]').inner_text
    end
    node.parent.css('a').each do |link|
      if link[:href].include?("Subjects")
        next_uri= BASE_URL + link[:href]
        get_subject_code(next_uri, file_name)
      else
        next
      end
    end
  end
end

def get_subject_code(uri, file_name)
  charset = nil

  doc = request_parsed_html(uri)
  file_name += ("_" + doc.at('//h1').inner_text)
  doc.xpath('//tr[@class="course- "]/td').each do |node|
    node.xpath('div[@class="subject-item"]').each do |child_node|
      child_node.css('a').each do |link|
        next_uri = URI.encode(BASE_URL + (link[:href].gsub(/\\u([\da-fA-F]{4})/) { [$1].pack('H*').unpack('n*').pack('U*') }))
        get_bg_success(next_uri, file_name)
      end
    end
  end
end

def get_bg_success(uri,file_name)
  row = Array.new(2)
  column = Array.new(1)
  subject_title = Array.new

  doc = request_parsed_html(uri)
  doc.xpath('//table[@id="MainContent_SubjectSyllabus_wariaiTable"]').each do |node|
    node.xpath('tr[@class="bg-success"]/th').each do |child_node|
      row << child_node.inner_text
    end

    node.xpath('tr[not(@*)]/th').each do |child_node|
      column << child_node.inner_text
    end

    table = Array.new(column.count).map{Array.new(row.count+2, nil)}
    subject_title = doc.at('//h1').inner_text

    node.xpath('tr[not(@*)]').each.with_index(0) do |child_node, j|
      child_node.xpath('*').each.with_index(1) do |grandson_node, k|
        table[j][k] = grandson_node.inner_text
      end
    end

    CSV.open("./shirabasu/#{file_name}.csv", "a") do |csv|
      csv << [subject_title]
      csv << row
      table.each do |chile_table|
        csv << chile_table
      end
      csv << []
    end
  end
end

#Benchmark.bm do |bm|
#  bm.report { get_school }
#end
get_school