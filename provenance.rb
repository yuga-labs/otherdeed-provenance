require 'json'
require 'digest'

lands = JSON.parse(File.read('./land_metadata.json'));1

provenance = {
    land_metadata: [],
    koda_metadata: []
}

class String
    def titlecase
        if !!match(/^id$/i)
            'ID'
        else
            split(/([[:alpha:]]+)/).map(&:capitalize).join
        end
    end
end

@index_to_cardinal_direction = {0 => 'Eastern', 1 => 'Southern', 2 => 'Western', 3 => 'Northern'}

def generate_attributes_list(metadata, prefix='', attributes = [])
    metadata.each_pair do |key, value|
        case value
        when Hash
            generate_attributes_list(value, "#{prefix} #{key.titlecase}".strip, attributes)
        when Array
            value.each_with_index do |sub_val, index|
                next unless sub_val # skip if subval is nil
                generate_attributes_list(sub_val, "#{prefix} #{@index_to_cardinal_direction[index]} #{key.titlecase[0...-1]}".strip, attributes)
            end
        else
            next unless value
            case key
            when 'id'
                attributes << {'trait_type' => prefix, 'value' => value}
            when 'tier'
                attributes << {'trait_type' => "#{prefix} Tier", 'value' => value.match(/Tier (\d+)/)[1].to_i, 'display_type': 'number'}
            else
                attributes << {'trait_type' => "#{prefix} #{key.titlecase}".strip, 'value' => value}
            end
        end
    end
    attributes
end

lands.each do |land|
    attributes = land['metadata'].clone
    metadata = {attributes: generate_attributes_list(attributes)}
    provenance[:land_metadata] << metadata.clone
end;1

kodas = JSON.parse(File.read('./koda_metadata.json'));1

kodas.each do |koda|
    provenance[:koda_metadata] << {attributes: koda}
end;1

provenance_hash = Digest::SHA256.hexdigest(provenance.to_json)
File.write("provenance_hash.txt", provenance_hash)
puts "PROVENANCE HASH: #{provenance_hash}"