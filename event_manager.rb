require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin 
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue
    "You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_number)
  phone_number.gsub!(/[^\d]/, '')
  if phone_number.length == 10
    phone_number.class
  elsif phone_number.length == 11 && phone_number[0] == "1"
    phone_number[1..10]
  else
    "non valid phone number"
  end
end

def reg_activity(s_date, to_array)
  date = Time.strptime(s_date, "%m/%d/%y %k:%M")
  hour = date.strftime("%k")
  day = date.strftime("%A")
  to_array == "hours" ? hour : day
end

def counting(array)
  array.reduce(Hash.new(0)) do |count, time|
    count[time] += 1
    count
  end
end

puts "Event Manager Initialized!"

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
reg_hours = []
reg_days = []
hour_count = {}
day_count = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zip = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zip)
  
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
  clean_phone_numbers(row[:homephone])
  reg_hours.push(reg_activity(row[:regdate], "hours"))
  reg_days.push(reg_activity(row[:regdate], "days"))
  hour_count = counting(reg_hours)
  day_count = counting(reg_days)
end

puts "Advertisement is best placed on hours:"
hour_count.each { |k,v| puts "#{k}:00" if v == hour_count.values.max}

puts "While the best day of the week is:"
day_count.each { |k,v| puts k if v == day_count.values.max}
