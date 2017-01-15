require 'json'

APP_PATH = Dir.pwd

require "#{APP_PATH}/inc/ext/gtfs-db-helpers/gtfs_db.rb"
require "#{APP_PATH}/inc/ext/profiler.rb"
require "#{APP_PATH}/inc/ext/custom-swiss-all.rb"

Profiler::init('START')

gtfs_importer_path = "/Users/vasile/Stuff/projects/gtfs/gtfs-importer"
gtfs_profile = "swiss-all"

db_path = "#{gtfs_importer_path}/tmp/#{gtfs_profile}/gtfs.db"
db = GTFS_DB::db_with_path(db_path)

Profiler::init('... query trips')

# post, vbz, tpg, sbb
extra_sql = " WHERE agency_id IN ('000801', '000849', '000881', '000011')"
# extra_sql = " WHERE agency_id IN ('000801')"
extra_sql = ""

sql = "SELECT * FROM trips #{extra_sql}"
rows = db.execute(sql)

Profiler::init("... got #{rows.size} trips")

map_agency_line = {}

rows.each do |row|
    agency_id = row['agency_id']
    vehicle_type = row['vehicle_type']
    fplan_vehicle_type = row['fplan_vehicle_type']
    trip_short_name = row['trip_short_name']

    trip_data = {
        'agency_id' => agency_id,
        'vehicle_type' => vehicle_type,
        'fplan_vehicle_type' => fplan_vehicle_type,
        'trip_short_name' => trip_short_name,

        'vehicle_types_order' => 0,
    }

    if map_agency_line[agency_id].nil?
        map_agency_line[agency_id] = {}
    end

    if map_agency_line[agency_id][vehicle_type].nil?
        map_agency_line[agency_id][vehicle_type] = {}
    end

    if map_agency_line[agency_id][vehicle_type][trip_short_name].nil?
        vehicle_line_sort = CustomExport::stop_services_sort_value(trip_data)

        map_agency_line[agency_id][vehicle_type][trip_short_name] = {
            'trip_short_name' => trip_short_name,
            'fplan_vehicle_type' => fplan_vehicle_type,
            'vehicle_line_sort' => vehicle_line_sort,
            'count' => 0,
        }
    end

    map_agency_line[agency_id][vehicle_type][trip_short_name]['count'] += 1
end

map_agency_line_path = "#{Dir.pwd}/agency_colors.json"
File.open(map_agency_line_path, "w") {|f| f.write(JSON.pretty_generate(map_agency_line)) }
print "Saved #{map_agency_line.values.size} agencies in #{map_agency_line_path}\n"

Profiler::init('DONE')

