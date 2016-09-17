require 'System.Xml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
require 'saxon9pe-api.dll' # pro version.
require 'tools'

class Pathname
    def to_uri
        System::Uri.new( "file:///" + self.expand_path.to_s )
    end
end

class String
    
    def to_qname
        Saxon::Api::QName.new( System::Xml::XmlQualifiedName.method(:new).overload(System::String).call(self) )
    end
        
    def to_xdm
        Saxon::Api::XdmAtomicValue.new(self.to_clr_string) # need explicit to_clr_string to aid overload resolution
    end

end

module Brotherus

    class SaxonTransformer
        include Saxon::Api

        def initialize
            processor = Processor.new( true ) # true: Schema-aware pro-version of the processor. Allows SAXON xslt-extensions. Requires SAXON_HOME to be set to dir with dir/bin
            @builder = processor.NewDocumentBuilder()
            @compiler = processor.NewXsltCompiler()
        end
               
        def transformer(xslt_file)  
            # We have removed the caching of transformers since
            # the parameters for them were then saved as well and
            # found no way to clear them
            @compiler.Compile( xslt_file.to_uri ).Load()
        end
        
        def xml_writer_settings
            settings = System::Xml::XmlWriterSettings.new
            settings.OmitXmlDeclaration = true
            settings
        end
        
        def transform( par_dict, xml_file, xslt_file )
            puts "transforming with #{xslt_file}"
            transformer = transformer(xslt_file)
            xml = @builder.Build( xml_file.to_uri )
            transformer.InitialContextNode = xml
            sb = System::IO::StringWriter.new
            xml_writer = System::Xml::XmlWriter.Create( sb, xml_writer_settings )
			puts 'Parameters:'
            par_dict.each_pair do | par_name, value |
                transformer.SetParameter( par_name.to_s.to_qname, value.to_s.to_xdm )
				puts "- #{par_name.to_s} = #{value.to_s}"
            end
            transformer.Run( TextWriterDestination.new( xml_writer ) )
            sb.ToString()
        end
        
    end

end