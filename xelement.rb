require 'System.Xml.Linq, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
require 'System.Xml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'

module System::Xml::Linq
    class XElement

        XPath = System::Xml::XPath::Extensions
        # In C#, functions below are extension methods, but in ruby
        # we need to mubgle them explicitly to the class to see them
        def xpath_select_element(xpath)
            XPath.XPathSelectElement(self, xpath)
        end

        def xpath_select_elements(xpath)
            XPath.XPathSelectElements(self, xpath).to_a
        end

        def xpath_evaluate(xpath)
            XPath.XPathEvaluate(self, xpath)
        end

        def each_element(&block)
            child_elements().each(&block)
        end

        def add_element(name,value=nil)
            xelement = XElement.new(XName.get(name.to_s))
            if value.is_a?(Hash)
                xelement.add_attributes(value)
            elsif value
                xelement.add(XText.new(value.to_s))
            end
            self.add(xelement)
            xelement
        end
        
        def add_attribute(name,value)
            if attribute(name)
                attribute(name).value = value.to_s
            else
                self.add(XAttribute.new(XName.get(name.to_s),value.to_s))
            end
        end

        def add_attributes(attributes)
            attributes.each do |name,value|
                add_attribute(name,value)
            end
        end
        
        def remove_element(name)
            SetElementValue( XName.get(name.to_s), nil )
        end
        
        def remove_attribute(name)
            SetAttributeValue( XName.get(name.to_s), nil )
        end

        # In C#, string name is automaticly converted to XName
        # with implicit conversion. This does not happen in Ruby,
        # so make the conversion explicit with XName.get(name)

        alias :child_element :element

        def element(name = nil, create_if_needed = false)
            if name
                el = child_element(XName.get(name.to_s))
                return el if el
                return add_element( name ) if create_if_needed
                nil
            else
                XPath.XPathSelectElement(self, "*[1]")
            end
        end

        alias :child_elements :elements

        def elements(name = nil)
            if name
                child_elements(XName.get(name.to_s))
            else
                child_elements()
            end
        end

        alias :element_name :name # avoid conflict with possible custom re-definitions for name

        alias :element_value :value # avoid conflict with possible custom re-definitions for value

        undef_method :name # allow redefinition of name with mix-ins
        undef_method :value # allow redefinition of name with mix-ins

        alias :original_attribute :attribute

        def attribute(name)
            original_attribute(XName.get(name.to_s))
        end
        
        def [](name)
            self.attribute(name) ? self.attribute(name).value : nil
        end
        
        def []=(name,value)
            add_attribute(name,value)
        end
        
        def self.create(name, *items)
            XElement.new( XName.get(name.to_s), *items )
        end

    end

    class XAttribute

        def self.create(name, value)
            XAttribute.new( XName.get(name.to_s), value )
        end

    end

end

