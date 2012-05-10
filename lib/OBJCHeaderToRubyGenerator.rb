
class OBJCHeaderToRubyGenerator
    attr_reader :header, :destination
    
    def initialize(headerPath, destinationPath)
        headerPath = File.expand_path(headerPath)
        destinationPath = File.expand_path(destinationPath)
        
         raise ArgumentError.new("expected #{headerPath} to exist") if ! File.exists?(headerPath)
         raise ArgumentError.new("expected #{destinationPath} to exist") if ! File.exists?(destinationPath)
         
         @header = File.open(headerPath, "r")
         
         rubyFile = headerPath.lastPathComponent.stringByDeletingPathExtension
         rubyFile = rubyFile.stringByAppendingPathExtension("rb")
         @destination = File.join(destinationPath, rubyFile)
    end
    
    def generate
        destFile = File.open(self.destination, "w")
        header.each do |line|
            if line =~ /^@interface/
                className = interface(line)
                destFile.puts(className)
            elsif line =~ /^@property/
                prop = property(line)
                destFile.puts("\t" + prop)
            elsif line =~ /^(\-|\+)/
               sig = objcMethod(line)
               destFile.write("\n")
               destFile.puts("\t" + sig)
            end
        end
        destFile.puts("end")
        destFile.close
    end
    
    private
    ##
    # convert a inteface line like:
    # => @inteface MyClass : SuperClass <SomeProtocol>
    # => into:
    # => class MyClass < SuperClass #<SomeProtocol>
    # => protocols are commented out but left in place a clue that the class expects to confrom to the protocol
    #
    def interface(line)
        className = line.gsub(/^@interface /, "").sub(/\</, "#<")
        className = className.sub(/\:/, "<")
        return "class " + className
    end
    
    ##
    # convert @property declarations:
    # => @proptery(nonatomic, retain) Foo *foo;
    # => attr_accessor :foo
    # => @property(nonatomic, readonly) Foo *foo;
    # => attr_reader :foo
    #
    def property(line)
        prop = line.sub(/^@property/, "")
        
        opts = prop.slice!(/\((.)+\)/)
        accessorType = "attr_accessor"
        if opts =~ /readonly/
            accessorType = "attr_reader"
        end
        
        prop = prop.slice!(/(\*)?(\w)+;/).sub(/\*/, "").sub(/;/, "")
       
        return accessorType + " :" + prop
    end
    
    ##
    # convert object-c method signatures into ruby
    # => - (void)foo:(id)sender -> def foo(sender)
    # => - (void)foo:(MyArg *)arg1 arg2:(MyArg *)bar -> def foo(arg1, arg2:bar)
    # => + (void)myClassMethod -> def self.myClassMethod
    #
    def objcMethod(line)
        type = "def "
        if line.start_with?("+")
            type = "def self."
        end
        
        sig = type
        line = line.sub(/\(\w+\)/, "")
        parsedFirst = false
        line.gsub(/((\w)+)+(:*\(\w+(\s|\*)*\)\w+)*/) do |match|
            if ! parsedFirst 
                sig = sig + match.sub(/(\:)*\((\w)+(\s)*(\*)*\)/, "(")
                parsedFirst = true
            else
                sig = sig + ", " + match.sub(/\((\w)+(\s)*(\*)*\)/, "")
            end
        end
        
        if sig =~ /\(/
            sig = sig + ")"
        end
        
        return sig + "\n" + "\tend"
    end
end