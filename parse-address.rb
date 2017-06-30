#$:.unshift File.expand_path("/Users/lyanco/workspace/fuigo/street-address", __FILE__)
require 'active_support/core_ext/string'
require 'ruby_postal/parser'
require 'csv'


COLS = {
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

STATE_ABBR_TO_NAME = {
    'AL' => 'Alabama',
    'AK' => 'Alaska',
    'AS' => 'America Samoa',
    'AZ' => 'Arizona',
    'AR' => 'Arkansas',
    'CA' => 'California',
    'CO' => 'Colorado',
    'CT' => 'Connecticut',
    'DE' => 'Delaware',
    'DC' => 'District of Columbia',
    'FM' => 'Federated States Of Micronesia',
    'FL' => 'Florida',
    'GA' => 'Georgia',
    'GU' => 'Guam',
    'HI' => 'Hawaii',
    'ID' => 'Idaho',
    'IL' => 'Illinois',
    'IN' => 'Indiana',
    'IA' => 'Iowa',
    'KS' => 'Kansas',
    'KY' => 'Kentucky',
    'LA' => 'Louisiana',
    'ME' => 'Maine',
    'MH' => 'Marshall Islands',
    'MD' => 'Maryland',
    'MA' => 'Massachusetts',
    'MI' => 'Michigan',
    'MN' => 'Minnesota',
    'MS' => 'Mississippi',
    'MO' => 'Missouri',
    'MT' => 'Montana',
    'NE' => 'Nebraska',
    'NV' => 'Nevada',
    'NH' => 'New Hampshire',
    'NJ' => 'New Jersey',
    'NM' => 'New Mexico',
    'NY' => 'New York',
    'NC' => 'North Carolina',
    'ND' => 'North Dakota',
    'OH' => 'Ohio',
    'OK' => 'Oklahoma',
    'OR' => 'Oregon',
    'PW' => 'Palau',
    'PA' => 'Pennsylvania',
    'PR' => 'Puerto Rico',
    'RI' => 'Rhode Island',
    'SC' => 'South Carolina',
    'SD' => 'South Dakota',
    'TN' => 'Tennessee',
    'TX' => 'Texas',
    'UT' => 'Utah',
    'VT' => 'Vermont',
    'VI' => 'Virgin Island',
    'VA' => 'Virginia',
    'WA' => 'Washington',
    'WV' => 'West Virginia',
    'WI' => 'Wisconsin',
    'WY' => 'Wyoming'
  }

def make_address(address, part)
  unless part.nil? || part.strip.empty?
    address += " "
    address += part.strip
  end
  return address
end

def remove_commas(str)
  return str.gsub(/,/, "")
end

def combine_fields(address, matched_labels)
  output = ""
  address.each do |part|
    if matched_labels.include? part[:label]
      output += remove_commas(part[:value])
      output += " "
    end
  end
  output.strip!
  return output
end


def get_line1(address)
  output = combine_fields(address, [:number, :house, :house_number, :road])
  output = output.split(" ").map(&:capitalize).join(' ')
  output += ","
  return output
end

def get_line2(address)
  output = combine_fields(address, [:unit, :level, :staircase, :entrance, :po_box])
  output = output.split(" ").map(&:capitalize).join(' ')
  output += ","
  return output
end

def get_city(address)
  output = combine_fields(address, [:city, :suburb, :city_district])
  output = output.split(" ").map(&:capitalize).join(' ')
  output += ","
  return output
end

def get_state(address)
  output = combine_fields(address, [:state, :state_district])
  output = output.upcase
  unless STATE_ABBR_TO_NAME[output].nil?
    output = STATE_ABBR_TO_NAME[output]
  end
  output += ","
  return output
end

def get_postcode(address)
  output = ""
  address.each do |part|
    if [:postcode].include? part[:label]
      output += make_US_postcode_5_digits(remove_commas(part[:value]))
      output += " "
    end
  end
  output.strip!
  output = output.upcase
  output += ","
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
  output = combine_fields(address, [:country, :country_region])
  output = output.upcase
  output += ","
  return output
end

def parse_address(row, cols)
  output_address = ""
  address = ""
  address = make_address(address, row[cols[:address]].to_s)
  address = make_address(address, row[cols[:city]].to_s)
  address = make_address(address, row[cols[:state]].to_s)
  address = make_address(address, row[cols[:zip]].to_s)
  address = make_address(address, row[cols[:country]].to_s)

  address.strip!
  address.gsub!(/,/, "")
  address.squish!

  if address.empty? || address.blank?
    address = nil #libpostal processes nil as [] but throws an exception for "" and " "
  end

  address = Postal::Parser.parse_address(address)
  output_address = ""
  output_address += get_line1(address)
  output_address += get_line2(address)
  output_address += get_city(address)
  output_address += get_state(address)
  output_address += get_postcode(address)
  output_address += get_country(address)
  return output_address
end



CSV_FILE_PATH = File.join("./input.csv")
arr = CSV.read("./input.csv", :encoding => 'windows-1251:utf-8')
#puts arr
arr.each do |row|
  unless row[COLS[:display_name]].to_s.strip.empty?
    output_row = ""
    output_row += remove_commas(row[COLS[:display_name]].to_s) + ","
    output_row += remove_commas(row[COLS[:email1]].to_s) + ","
    output_row += remove_commas(row[COLS[:phone1]].to_s) + ","
    output_row += remove_commas(row[COLS[:phone2]].to_s) + ","
    output_row += parse_address(row, COLS)
    output_row += remove_commas(row[COLS[:notes]].to_s) + " " + remove_commas(row[COLS[:webpage]].to_s)
    puts output_row
  end
end
