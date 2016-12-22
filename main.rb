require 'watir-webdriver'
require 'pry'

switches = %W[--user-data-dir=tmp/chrome-profile/]
b = Watir::Browser.new :chrome, switches: switches

NATION = ENV['NB_NATION']
EMAIL = ENV['NB_USER']
PASSWORD = ENV['NB_PASS']
TAG_PATTERNS_TO_DELETE = [
  /temp/i
]

begin
  b.goto "https://#{NATION}.nationbuilder.com/login"
  b.text_field(label: 'Email Address').set(EMAIL)
  b.text_field(label: 'Password').set(PASSWORD)
  b.button(text: 'Sign in with email').click
  sleep 2

  b.goto "https://#{NATION}.nationbuilder.com/admin/signup_tags/new"
  total_tags = b.div(class: 'total-found').text.match(/([\d,]+)$/)[1] rescue 1
  pages = (total_tags.gsub(/,/,'').to_i / 50.0).ceil # they show 50 tags per page

  tag_ids = []
  (1..pages).to_a.reverse.each do |page_number|
    b.goto "https://#{NATION}.nationbuilder.com/admin/signup_tags/new?page=#{page_number}"
    tags = b.links(href: /tag_id/, text: Regexp.union(TAG_PATTERNS_TO_DELETE))
    tag_ids << tags.map(&:href).map{|u| u.match(/=(\d+)/)[1] }
  end
  tag_ids.flatten!

  puts "about to delete #{tag_ids.length} tags"
  printf "=> press 'y' to continue: "
  prompt = STDIN.gets.chomp
  exit unless prompt == 'y'

  tag_ids.each do |tag_id|
    b.goto "https://#{NATION}.nationbuilder.com/admin/signup_tags/#{tag_id}/edit"
    b.link(text: 'Delete Tag').click rescue next
  end

rescue Exception => e
  puts e
  binding.pry
ensure
  b.quit
end
