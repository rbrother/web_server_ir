require 'cgi'

module Brotherus

    class Request
        
        def initialize( ip, raw_request_string )
            # the request string encoding does not matter since all
            # 'difficult' chars in parameters are anyway URL-escaped at this point.
            # We will deal with that later
            @raw_request = raw_request_string
			@ip = ip
        end
    
	    def ip
			@ip
		end
	
        def raw
            @raw_request
        end
        
        def lines
            @lines ||= raw.split("\n").map { |line| line.strip }
        end
        
        def type
            head_parts[0]
        end
        
        # eg. /family/person?xmlFile=Brotherus.xml,xsltFile=PersonList.xslt,baseURL=xxx,dataURL=yyy
        def path
            head_parts[1].gsub('\\', '/')
        end
        
        def http_version
            head_parts[2]
        end
                  
        # Headers are lines like "Accept-Encoding: gzip,deflate,sdch"
        def headers
            @headers ||=
                Hash[ lines.grep(/^[\w-]+: /).
                    map { |header| header.match(/^([\w-]+): (.+)$/).to_a[1..-1] } ]
        end
        
        def print_headers
            headers.each { |key,value| puts "    '#{key}' => '#{value}'" }
        end
        
        def host
            headers['Host']
        end
        
        def [](par_name)
            parameters[par_name]
        end
                
        def parameters
            @parameters ||= parse_parameters( type == 'GET' ? get_path_parts.last : lines.last )
        end
        
        def app
            path_parts[0]
        end
        
        def page
            path_parts[1]
        end
                
    private    
    
        def head_parts
            lines.first.match(/(GET|POST) (.+) HTTP\/(\w.\w)/).to_a[1..-1]
        end    
    
        def path_parts
            type == 'GET' ? get_path_parts : post_path_parts
        end
        
        def post_path_parts # app, page
            path.match(/^\/([\w\.-]+)(?:\/([\w\.-]+)?)?$/).to_a[1..-1] || []
        end
        
        def get_path_parts # app, page, parameters
            path.match(/^\/([\w\.-]+)(?:\/(?:([\w\.-]+)(?:\?(.+))?)?)?$/).to_a[1..-1] || []
        end    
    
        def parse_parameters( parameters_text )
            parameters_text ? Hash[ parameters_text.split(/&/).map { |par| parse_parameter(par) } ] : {}
        end
        
        def parse_parameter(par)
            key,value = par.match(/^(.+)=(.*)$/).to_a[1..-1]
            raise "unable to parse parameter in x=y form: #{par}" unless key
            [ key.to_sym, decode_par(value) ]
        end

        def decode_par( s )
            s.sub!('%A0+',' ') # U+00A0 (NO-BREAK SPACE) seems to create problems when converting to dotnet string, so remove
            CGI.unescape(s).encode("iso-8859-1") # Ruby 1.9 default encoding is "ASCII-8BIT". This marks the text as iso-8859-1 encoded (ensure that you use iso-8859-1 encoding in html docs)
        end        
    
    end

end