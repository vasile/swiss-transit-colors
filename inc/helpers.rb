require 'yaml'

class SwissTransitHelpers
    def self.generate_html_from_colors_config
        settings_path = "#{APP_PATH}/agency_colors.yml"
        if !File.exists? (settings_path)
            print "Can't find #{settings_path}\nABORT\n"
            exit
        end
        
        settings = YAML.load_file(settings_path)

        trs = []

        settings['agency'].each do |agency_id, agency_data|
            agency_need_rowspan = true
            fplan_vehicle_types_count = agency_data['vehicle_types'].keys.size
            
            agency_data['vehicle_types'].each do |fplan_vehicle_type, fplan_vehicle_type_data|

                tds = []
                if agency_need_rowspan
                    tds.push("<td rowspan=\"#{fplan_vehicle_types_count}\" class=\"agency\">#{agency_data['agency_name']}<br/>#{agency_data['short_name']}<br/>#{agency_id}</td>")
                    agency_need_rowspan = false
                end

                tds.push("<td>#{fplan_vehicle_type}</td>")

                line_divs = []
                fplan_vehicle_type_data.keys.each do |service_line|
                    color_data = self::color_data_from_settings(settings, agency_id, fplan_vehicle_type, service_line)

                    if service_line == 'ALL_LINES'
                        service_line = fplan_vehicle_type
                    end

                    line_div = "<div class=\"service_line\" style=\"color:#{color_data['fg']}; background-color:#{color_data['bg']};\">#{service_line}</div>"
                    line_divs.push(line_div)
                end

                tds.push("<td>" + line_divs.join("\n") + "</td>")

                trs.push("<tr>" + tds.join("\n") + "</tr>")
            end
        end

        colors_html_path = "#{APP_PATH}/out/agency_colors_data.html"
        colors_html_template_path = "#{APP_PATH}/inc/colors_data.template.html"
        colors_html = File.open(colors_html_template_path, 'r').read
        colors_html = colors_html.sub('[TRs]', trs.join("\n"))

        File.open(colors_html_path, 'w') {|f| f.write(colors_html) }
        print "Saved to #{colors_html_path}\n"
    end

    def self.color_data_from_settings(settings, agency_id, fplan_vehicle_type, service_line)
        default_color = settings['special_colors']['DEFAULT']

        if settings['agency'][agency_id].nil?
            print "Failed to find #{agency_id} in the settings\n"
            return default_color
        end

        settings_agency = settings['agency'][agency_id]

        if settings_agency['default_color']
            default_color = settings_agency['default_color']
        end

        if settings_agency['vehicle_types'][fplan_vehicle_type].nil?
            print "Failed to find #{fplan_vehicle_type} in #{agency_id} settings\n"
            return default_color 
        end

        settings_vehicle_type = settings_agency['vehicle_types'][fplan_vehicle_type]

        if settings_vehicle_type['ALL_LINES']
            default_color = settings_vehicle_type['ALL_LINES']
        end

        if service_line == ''
            return default_color 
        end

        if settings_vehicle_type[service_line].nil?
            print "Failed to find #{service_line} in #{agency_id} > #{fplan_vehicle_type} settings\n"
            return default_color 
        end

        color_data = settings_vehicle_type[service_line]
        if color_data['fg'] == ''
            return default_color 
        end

        return color_data
    end
end