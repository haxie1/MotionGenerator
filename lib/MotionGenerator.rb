require "MotionGenerator/MGHeaderToRubyGenerator.rb"
require "MotionGenerator/MGProjectWatcher.rb"

module MotionGenerator
    
    def self.generate(header, destination)
        generator = MGHeaderToRubyGenerator.new(header, destination)
        generator.generate
    end
    
    def self.autogenerate(path, dest)
        puts "watching: #{path}"
        watcher = MGProjectWatcher.new
        watcher.watch(path) do |changes|
            changes.each do |change|
                if File.extname(change) == ".h"
                    puts "generating changes for: #{change}"
                    self.generate(change, dest)
                end
            end
        end 
    end
        
end
