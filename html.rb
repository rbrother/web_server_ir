require 'responses'

module Brotherus

module Html

    def self.page(title, body_content, stylesheet = nil)
        HtmlResponse.new %Q[
            <html>
                <head>
                    <title>#{title}</title>
				    #{stylesheet_link(stylesheet)}
				    <meta http-equiv="content-type" content="application/xhtml+xml; charset=ISO-8859-1" />
                </head>
                <body>
                    #{body_content}
                </body>
            </html>
        ]
    end
        
    def self.stylesheet_link(stylesheet)        
        %Q[<link rel="stylesheet" type="text/css" href="#{stylesheet}"/>] if stylesheet
    end

end

end