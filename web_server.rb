require 'pathname'
require 'cgi'
require 'responses'
require 'session'
require 'tools'
require 'request'
require 'html'

module Brotherus

    class WebServer
        include System::Net
        include System::Net::Sockets
        include System::Web
     
        # The constructor which make the TcpListener start listening on the
        # given port. It also calls a Thread on the method StartListen(). 
        def initialize(opt = {})
            @port = opt[:port] || 8082
            @app_name = opt[:app_name] || 'app'
            @app_dir = opt[:app_dir] || Pathname.new(Dir.pwd)
            @listeners = []
            puts "Web Server by Robert Brotherus"
            puts "Adding listener for port #{port}"
            my_listener = TcpListener.new( IPEndPoint.new( IPAddress.any, port ) )
            my_listener.Start()
            @listeners << my_listener
        end
    
        def app_name; @app_name; end
        
        def app_dir; @app_dir; end
        
        def port; @port; end
        
        def base_url
            "http://#{host_server}:#{port}/#{app_name}"
        end
        
        # This method Accepts new connection and
        # First it receives the welcome massage from the client,
        # Then it sends the Current date time to the Client.
        def start
            # start listing on the given port
            puts "Web Server Running... Press ^C to Stop..."
            get_and_process_request while true
        rescue Exception => ex            
            puts ex.to_s unless ex.class.to_s == 'Interrupt'
        end        
        
        def get_and_process_request
            my_socket = get_pending_listener().AcceptSocket()
            my_socket.receive_timeout = 5000 # millisecs. Prevent server being stalled on bad requests.
            puts "\n\n================== Processing Request =================="
            return unless my_socket.Connected
            duration = System::DateTime.measure_duration do                
                puts "Client Connected: #{my_socket.RemoteEndPoint}"
                purge_dead_sessions
                puts "sessions: #{sessions.inspect}"
                @remote_ip = my_socket.RemoteEndPoint.address.ToString()
                @request_bytes = System::Array.of(System::Byte).new(100000)
                i = my_socket.Receive( @request_bytes )                
                bytes = @request_bytes.take(i).to_a
                puts "#{i} bytes read"
                @request = Request.new( bytes.pack 'C*' )
                puts "Raw request:"
                puts request.lines                    
                puts "\nrequest_type: #{request.type}"
                if request.app == 'favicon.ico' # special request for icon from browser
                    puts "icon request -> ignore"
                    return NoReplyResponse.new 
                end
                request.print_headers                
                response = get_response()
                response.socket = my_socket
                response.send_to_browser
            end
            puts "Request processed in #{duration} s"
        rescue Exception => ex
            raise ex if ex.class.to_s == 'Interrupt'
            puts "\n!!!!!!!!!!!!!!!!!!!\n### web_server.rb / get_and_process_request handling exception:"        
            puts ex.message[0..256]
            puts ex.backtrace
            err = Html.page "#{app_name} - Error", "
                <h1>#{ex.class.to_s}: #{ex.message[0..256]}</h1>
                <p>#{ex.backtrace.join('<br/>')}</p>"
            err.socket = my_socket
            err.send_to_browser            
        ensure
            my_socket.Close() if my_socket
        end    
        
        def request
            @request
        end    
                        
        def sessions
            @sessions ||= {} # indexed by ip
        end
        
        def session
            sessions[@remote_ip] ||= Session.new
        end
        
        def current_username
            session[:username]
        end
        
        def host_parts
            # eg. request.host:   www.brotherus.net:8081
            request.host.match(/([^:]+)(:\d+)?$/).to_a[1..-1]
        end
        
        def host_server
            host_parts.first
        end
                        
        def purge_dead_sessions
            orig_length = sessions.length
            sessions.delete_if { | ip, sess | !sess.alive }
            purged_count = orig_length - sessions.length
            puts "Purged #{purged_count} dead sessions" if purged_count > 0
        end

        def get_pending_listener
            Thread.Sleep(100) while pending_listener?.nil?
            pending_listener?
        end
        
        def pending_listener?
            @listeners.find { | listener | listener.Pending() }
        end

    end
        
end