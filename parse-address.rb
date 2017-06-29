#$:.unshift File.expand_path("/Users/lyanco/workspace/fuigo/street-address", __FILE__)
#require 'active_support/core_ext/string'
require 'ruby_postal/parser'
require 'csv'


cols = {
  display_name: 0,
  nickname: 1,
  email1: 2,
  email2: 3,
  phone1: 4,
  phone2: 5,
  address: 6,
  city: 7,
  state: 8,
  zip: 9,
  country: 10,
  notes: 11,
  webpage: 12
}

def make_address(address, part)
  unless part.nil? || part.strip.empty?
    address += " "
    address += part.strip
  end
  return address
end

def process_postcode(postcode)
  if /^\d{4}$/ =~ postcode
    postcode = '0' + postcode
  elsif /^\d{3}$/ =~ postcode
    postcode = '00' + postcode
  end
  return postcode
end


CSV_FILE_PATH = File.join("./input.csv")
arr = CSV.read("./input.csv", :encoding => 'windows-1251:utf-8')
#puts arr
arr.each do |row|
  unless row[cols[:display_name]].nil? || row[cols[:display_name]].empty?
    address = ""
    address = make_address(address, row[cols[:address]].to_s)
    address = make_address(address, row[cols[:city]].to_s)
    address = make_address(address, row[cols[:state]].to_s)
    address = make_address(address, row[cols[:zip]].to_s)

    unless address.nil? || address.empty?
      address.strip!
      address.gsub!(/,/, "")
      address.gsub!(/\s+/," ")

      address = Postal::Parser.parse_address(address)
      unless address.nil?
        output_row = ""
        address.each do |part|
          output_row += " " unless output_row.empty?
          if part[:label] == :state
            output_row += part[:value].upcase
          elsif part[:label] == :postcode
            output_row += process_postcode(part[:value].upcase)
          else
            output_row += part[:value].split(" ").map(&:capitalize).join(' ')
          end
          output_row += "," unless part[:label] == :house_number
        end
        puts output_row
      end
    end
  end
end
