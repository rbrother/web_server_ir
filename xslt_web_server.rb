require 'rake' # for String.ext
require 'pathname'
require 'tools'
require 'web_server'
require 'saxon_transformer'
require 'role_based_sequrity'

module Brotherus

class XsltWebServer < WebServer
    include RoleBasedSequrity
    
    def initialize(opt = {})
        super
        @default_xslt = opt[:default_xslt] || 'index'
        @app_module = eval( opt[:app_module] || 'Brotherus' )
        Dir[(app_dir + 'db_actions' + '*.rb').to_s].each do |file|
            puts "require #{file}"
            require file
        end        
    end
    
    def default_xslt; @default_xslt; end
    
    def transformer
        @transformer ||= SaxonTransformer.new
    end
    
    def additional_xslt_parameters
        {} # override in inheriting class if needed
    end
        
    # Override if you need custom mapping of page names to action-classes
    # All page names that do not have action will be processed by XSLT-file based on the page name.
    def page_action(page_name)
        if page_name =~ /^(delete|post|modify|update|add)/i
            @app_module.const_get( page_name[0..0].upcase + page_name[1..-1] )
        end
    end

    # override if you have app data (xml, xslt) in different dir than app dir
    def app_data_root
        app_dir
    end
        
    def xml_file
        raise "inherited class must define full path to xml data file"
    end
     
    def get_response
        xslt_parameters = request.parameters.
            merge( { :baseURL => base_url } ).
            merge(additional_xslt_parameters).
            merge(session_xslt_params)
        puts "xslt_parameters: #{xslt_parameters.inspect}"
        catch(:response) do # allow exceptional responses be thrown from deeper
            if request.page =~ /^askPassword/i
                if request[:username] && request[:password]
                    log_in( request[:username], request[:password], request[:url] )
                else
                    ask_password( nil, request[:url] )
                end
            elsif request.page == /^logout/i
                log_out
            elsif action = page_action(request.page)
                check_permissions_for_editing()
                action.new(xml_file, request, session, self).run
            else
                check_permissions_for_viewing()
                HtmlResponse.new( transformer.transform( xslt_parameters, xml_file, xslt_file ) )
            end        
        end
    end
    
    def session_xslt_params
        if session[:username]
            { :username => session[:username],
              :password => 1, # for backward compatibility
              :roles => user_roles(current_user).join(' ') }
        else
            {}
        end
    end
    
    def xslt_file
        app_data_root + "xslt/#{xslt}.xslt"
    end
    
    # Override this in descendant class to specify custom logic for determination of xslt-file
    def xslt
        request.page.nil? || request.page == 'index' ? default_xslt : request.page
    end
    
    # Override this if special roles are required
    def check_permissions_for_editing()
        require_role 'editor' # all actions modify db
    end
    
    # Override this if special roles are required
    def check_permissions_for_viewing()
        require_role 'viewer'
    end

    # Override this if special roles are required
    def role_required(xslt_name)
        case xslt_name
            when /^edit/i
                'editor'
        end
    end
        
end

end # module
