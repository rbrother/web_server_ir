require 'tools'

module Brotherus

    class Response  
    
        # Wikipedia: The encoding Windows-1252 is a superset of ISO 8859-1, but differs 
        # from the IANA's ISO-8859-1 by using displayable characters rather than control 
        # characters in the 0x80 to 0x9F range. It is known to Windows by the code page 
        # number 1252, and by the IANA-approved name "windows-1252".
        ISO8859 = System::Text::Encoding.GetEncoding("ISO-8859-1")    
    
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
            send_bytes( string.to_bytes(ISO8859) )
        end
        
    end    
    
    class HtmlResponse < Response

        def initialize(html)
            @html = html
        end    
        
        def send_to_browser
            send_string "HTTP/1.0 200 OK\n" +
                "Content-Type: text/html;charset=ISO-8859-1\n" +
                "Accept-Ranges: bytes\n" +
                "Content-Length: #{@html.to_bytes(ISO8859).Length}\n\n" +
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

end