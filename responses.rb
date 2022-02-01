require 'tools'

module Brotherus

    class Response  
    
        UTF8 = System::Text::Encoding.GetEncoding("UTF-8")    
    
        attr_accessor :socket
        
        def send_bytes(bytes)
            if @socket.connected
                num_bytes = 0
                if ( num_bytes = @socket.Send( bytes, bytes.Length, 0 ) ) == -1
                    puts "Socket Error cannot Send Packet"
                else
                    puts "No. of bytes send #{num_bytes}"
                end
            else
                puts "Connection Dropped...."
            end        
        end
        
        def send_string(string)
            send_bytes( string.to_bytes(UTF8) )
        end
        
    end    
    
    class HtmlResponse < Response

        def initialize(html)
            @html = html
        end    
        
        def send_to_browser
            send_string "HTTP/1.0 200 OK\n" +
                "Content-Type: text/html;charset=UTF-8\n" +
                "Accept-Ranges: bytes\n" +
                "Content-Length: #{@html.to_bytes(UTF8).Length}\n\n" +
                @html
        end    
        
    end
    
    class NoReplyResponse < Response

        def send_to_browser
            send_string "HTTP/1.0 204 No Content\n\n"
        end
        
    end   
    
    class RedirectResponse < Response
    
        def initialize(url)
            @url = url
        end
        
        def send_to_browser
            puts "Redirecting to #{@url}"
            send_string "HTTP/1.0 302 Found\n" +
                "Location: #{@url}\n\n"
        end
        
    end 
    
    class PdfResponse < Response
    
        def initialize(filename)
            @filename = filename
        end
    
        def send_to_browser
            data = IO.read(@filename)
            send_string "HTTP/1.0 200 OK\n" +
                "Content-Type: application/pdf;" +
                "Content-Length: #{data.length}\n\n"
            send_bytes( data )
        end

    end
 
end