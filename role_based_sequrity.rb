require 'xelement'
require 'digest/md5'

require 'html'

module Brotherus

module RoleBasedSequrity
    
    def settings_file
        app_data_root + 'xml/settings.xml'
    end
    
    def settings
        @settings ||= System::Xml::Linq::XElement.load(settings_file.to_s)
    end    
    
    def users
        settings.xpath_select_elements('Users/User')
    end
    
    def current_user
        find_user(current_username) # client must define current_username method
    end    
           
    def find_user(username)
        users.find { |user| user.attribute('Name').value == username }
    end
    
    def user_roles(user)    
        user ? 
            user.xpath_select_elements('Roles/Role').map { |role| role.Value } :
            []
    end
	
	def current_user_roles
		user_roles(current_user)
	end
    
    def has_role(role)
		current_user_roles.include?('admin') || user_roles(current_user).include?(role)
    end
    
    def require_role(role)
        unless has_role(role)
            throw(:response, RedirectResponse.new(
                "#{base_url}/askPassword?url=#{CGI.escape(request.path)}"
            ))
        end    
    end

    def ask_password( given_username, prev_url )
        # client must define html_page method method
        Html.page('Password', ask_password_content( given_username, prev_url ) )
    end
    
    def log_in( username, password, prev_url)       
        puts "log_in"
        if find_user(username) 
            if find_user(username).attribute('PasswordMD5').value == Digest::MD5.hexdigest(password)
                session[:username] = username # log-in ok
                RedirectResponse.new( return_to_url(prev_url) )
            else
                puts "incorrect password"
                ask_password( username, prev_url )
            end
        else
            puts "User not found: #{username}"
            ask_password( username, prev_url )
        end        
    end  
	
    def return_to_url( prev_url) 
        ( prev_url && prev_url != '' ) ? prev_url : base_url
    end	
    
    def log_out
        sessions.clear
        RedirectResponse.new(base_url)
    end      

    def ask_password_content( given_username, prev_url )
        %Q[
            <form method="post" action="#{base_url}/askPassword">
                <div style="width: 600px;">
                    <p>The requested operation requires personal username and password. 
                    One username per person. The old shared password does not work any more.
                    All edits of the database are logged.
                    Please contact <a href="mailto:robert@iki.fi">robert@iki.fi</a>
                    to get username. I apologize for the inconvenience.</p>
                    <p>Pyydetty operaatio vaatii tunnuksen ja salasanan.
                    Ota yhteyttä <a href="mailto:robert@iki.fi">robert@iki.fi</a> saadaksesi
                    nämä. Pahoittelen vaivannäköä.</p>
                    <p>Username <input type="text" name="username"/></p>
                    <p>Password <input type="password" name="password"/></p>
                    <p><input type="submit" value="Submit Password"/></p>
                    <p style="font-weight: bold; color: red;">#{given_username ? 'Invalid username or password, try again' : ''}</p>
                </div>
                <input type="hidden" name="url" value="#{prev_url}"/>
            </form>
        ]
    end

end

end