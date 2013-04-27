module Brotherus

    class Session
        
        def initialize
            puts "Created new session"
            @start_time = Time.now
        end
        
        def alive
            (Time.now - @start_time) < 3600
        end
        
        def params
            @params ||= {}
        end
        
        def []=(index, value)
            params[index] = value
        end
        
        def [](index)
            params[index]
        end
        
    end

end