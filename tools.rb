class String

    def to_bytes(encoding)
        encoding.GetBytes(self)
    end
    
end

class Exception
    
    def to_verbose_s
        self.respond_to?(:ToString) ? self.ToString() : self.to_s()
    end
    
end

class System::DateTime
    
    def self.measure_duration
        start = self.Now
        yield
        (self.Now - start).TotalSeconds
    end
    
end

class Utils

    def self.irb(bind)
        while true
            print "> "
            s = gets()
            return if s =~ /^exit/
            begin
                result = eval(s, bind)
                puts
                puts "   " + result.inspect
            rescue Exception => ex
                puts ex.to_s
            end
        end
    end

end