require 'YAML'
require 'json'

APP_PATH = Dir.pwd

require "#{APP_PATH}/inc/ext/gtfs-db-helpers/gtfs_db.rb"
require "#{APP_PATH}/inc/ext/profiler.rb"
require "#{APP_PATH}/inc/ext/custom-swiss-all.rb"

gtfs_importer_path = "/Users/vasile/Stuff/projects/gtfs/gtfs-importer"
gtfs_profile = "swiss-all"

config_path = "#{gtfs_importer_path}/inc/custom/#{gtfs_profile}/custom.yml"
config = YAML.load_file(config_path)

db_path = "#{gtfs_importer_path}/tmp/#{gtfs_profile}/gtfs.db"
db = GTFS_DB::db_with_path(db_path)

sql = "SELECT * FROM agency"
rows = db.execute(sql)

map_agency = {}
rows.each do |row|
    agency_id = row['agency_id']
    map_agency[agency_id] = row
end

map_agency_line_path = "#{Dir.pwd}/agency_colors.json"
map_agency_line = JSON.parse(File.open(map_agency_line_path, "r").read)

config_lines = []
config_lines << %q{special_colors:
    DEFAULT: &DEFAULT
        bg: "#91c1e6"
        fg: "#000000"
    NIGHT: &NIGHT
        bg: "#000000"
        fg: "#fff100"
    TRAIN_SBAHN: &TRAIN_SBAHN
        bg: "#003399"
        fg: "#ffffff"
    TRAIN_LONG_DISTANCE: &TRAIN_LONG_DISTANCE
        bg: "#ed232a"
        fg: "#ffffff"

agency_data:}

agency_data = map_agency.values.sort_by{ |el| el['agency_code'] }
agency_data.each do |agency_row|
    agency_id = agency_row['agency_id']

    config_lines << "    # #{agency_row['agency_name']} - #{agency_row['agency_short_name']}"
    config_lines << "    \"#{agency_id}\":"
    config_lines << "        code: #{agency_row['agency_code']}"
    config_lines << "        short_name: #{agency_row['agency_short_name']}"
    config_lines << "        name: #{agency_row['agency_name']}"
    config_lines << "        colors_source:"
    config_lines << "        color_by_types:"   

    vehicle_types_data = map_agency_line[agency_id]
    next if vehicle_types_data.nil?
    vehicle_types_data.each do |vehicle_type, vehicle_type_data|
        # config_lines << "            # FPLAN: #{vehicle_type_data['fplan_types'].sort.join(',')}"
        config_lines << "            #{vehicle_type}:"

        vehicle_type_lines = vehicle_type_data.values.sort_by{ |el| el['vehicle_line_sort'] }
        vehicle_type_lines.each do |line_data|
            trip_short_name = line_data['trip_short_name']
            if trip_short_name == ""
                trip_short_name = "ALL_LINES"
            end
            # config_lines << "                # #{line_data['count']} vehicles"
            # config_lines << "                \"#{trip_short_name}\": # #{line_data['vehicle_line_sort'].ljust(20, ' ')} #{line_data['fplan_vehicle_type']} -> #{line_data['count']} vehicles"
            config_lines << "                \"#{trip_short_name}\":"

            trip_data = {
                'vehicle_type' => vehicle_type,
                'fplan_vehicle_type' => line_data['fplan_vehicle_type'],
                'trip_short_name' => line_data['trip_short_name'],
                'vehicle_types_order' => 0,
                'agency_id' => agency_id,
            }

            colors_to_use = nil
            if trip_short_name == "ALL_LINES"
                colors_to_use = "DEFAULT"
            end

            if vehicle_type == "train"
                if CustomExport::is_sbahn(trip_data)
                    colors_to_use = "sbahn"
                else
                    colors_to_use = "train_long_distance"
                end 
            end

            if CustomExport::is_night_service(trip_data)
                colors_to_use = "night"
            end

            if colors_to_use
                case colors_to_use
                when "DEFAULT"
                    config_lines << "                    <<: *DEFAULT"
                when "sbahn"
                    config_lines << "                    <<: *TRAIN_SBAHN"
                when "train_long_distance"
                    config_lines << "                    <<: *TRAIN_LONG_DISTANCE"
                when "night"
                    config_lines << "                    <<: *NIGHT"
                else
                    config_lines << "                    bg: \"\""
                    config_lines << "                    fg: \"\""
                end
            else
                bg_color = ''
                fg_color = ''

                color_data = color_data_from_old_config(trip_data)
                if color_data
                    bg_color = color_data['bg']
                    fg_color = color_data['fg']
                end

                config_lines << "                    bg: \"#{bg_color}\""
                config_lines << "                    fg: \"#{fg_color}\""
            end
        end
    end
    config_lines << ""
end

mapping_file_path = "#{Dir.pwd}/agency_colors2.yml"
File.open(mapping_file_path, "w") {|f| f.write(config_lines.join("\n")) }

print "Saved colors data in #{mapping_file_path}\n"

