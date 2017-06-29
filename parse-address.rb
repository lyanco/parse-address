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



def get_line1(address)
  output = ""
  address.each do |part|
    if [:number, :house, :house_number, :road].include? part[:label]
      output += part[:value]
      output += " "
    end
  end
  output.strip!
  output += ","
  output = output.split(" ").map(&:capitalize).join(' ')
  return output
end

def get_line2(address)
  output = ""
  address.each do |part|
    if [:unit, :level, :staircase, :entrance, :po_box].include? part[:label]
      output += part[:value]
      output += " "
    end
  end
  output.strip!
  output += ","
  output = output.split(" ").map(&:capitalize).join(' ')
  return output
end

def get_city(address)
  output = ""
  address.each do |part|
    if [:city, :suburb, :city_district].include? part[:label]
      output += part[:value]
      output += " "
    end
  end
  output.strip!
  output += ","
  output = output.split(" ").map(&:capitalize).join(' ')
  return output
end

def get_state(address)
  output = ""
  address.each do |part|
    if [:state, :state_district].include? part[:label]
      output += part[:value]
      output += " "
    end
  end
  output.strip!
  output += ","
  output = output.upcase
  return output
end

def get_postcode(address)
  output = ""
  address.each do |part|
    if [:postcode].include? part[:label]
      output += make_US_postcode_5_digits(part[:value])
      output += " "
    end
  end
  output.strip!
  output += ","
  output = output.upcase
  return output
end


def make_US_postcode_5_digits(postcode)
  if /^\d{4}$/ =~ postcode
    postcode = '0' + postcode
  elsif /^\d{3}$/ =~ postcode
    postcode = '00' + postcode
  end
  return postcode
end

def get_country(address)
  output = ""
  address.each do |part|
    if [:country, :country_region].include? part[:label]
      output += part[:value]
      output += " "
    end
  end
  output.strip!
  output += ","
  output = output.upcase
  return output
end

def parse_address(row, cols)
  output_address = ""
  unless row[cols[:display_name]].nil? || row[cols[:display_name]].empty?
    address = ""
    address = make_address(address, row[cols[:address]].to_s)
    address = make_address(address, row[cols[:city]].to_s)
    address = make_address(address, row[cols[:state]].to_s)
    address = make_address(address, row[cols[:zip]].to_s)
    address = make_address(address, row[cols[:country]].to_s)


    unless address.nil? || address.empty?
      address.strip!
      address.gsub!(/,/, "")
      address.gsub!(/\s+/," ")

      address = Postal::Parser.parse_address(address)
      unless address.nil?
        output_address = ""
        output_address += get_line1(address)
        output_address += get_line2(address)
        output_address += get_city(address)
        output_address += get_state(address)
        output_address += get_postcode(address)
        output_address += get_country(address)
      end
    end
  end
  puts output_address
  return output_address
end



CSV_FILE_PATH = File.join("./input.csv")
arr = CSV.read("./input.csv", :encoding => 'windows-1251:utf-8')
#puts arr
arr.each do |row|
  parse_address(row, cols)
end
