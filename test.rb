require 'typhoeus' #Thread request uri
hydra = Typhoeus::Hydra.new
requests = 10.times.map {
  request = Typhoeus::Request.new("https://syllabus.kosen-k.go.jp/Pages/PublicSchools")
  hydra.queue(request)
  request
}
puts requests
hydra.run
puts "hydra run"
puts requests

responses = requests.map { |request|
  puts request.response.body

}