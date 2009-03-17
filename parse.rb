# install json library
# sudo gem install json

# good json/ruby example
# http://pmwjournal.blogspot.com/2006/03/json-ajax-ruby-on-rails.html

require 'rubygems'
require 'json'
require 'net/http'

class JSON_Processor
  attr_accessor :params, :response

  def initialize(*args)
    @params = args
    @base_url = @params[0]
  end

  def search(query, results=10, start=1)
     url = "#{@base_url}&query=#{URI.encode(query)}&results=#{results}&start=#{start}"
     resp = Net::HTTP.get_response(URI.parse(url))
     data = resp.body

     # convert JSON to native Ruby hash
     @response = JSON.parse(data)

     # if hash has 'Error' as a key, raise an error
     if @response.has_key? 'Error'
        raise "web service error"
     end
  end
end

news = JSON_Processor.new(
        "http://search.yahooapis.com/NewsSearchService/V1/newsSearch?appid=YahooDemo&output=json"
        )

news.search('ruby', 2)

news.response['ResultSet']['Result'].each { |item|
  print "#{item['Title']} => #{item['Url']}\n"
}
