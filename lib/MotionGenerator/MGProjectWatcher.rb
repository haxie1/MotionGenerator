framework 'ApplicationServices'

module MotionGenerator
    
    class MGProjectWatcher
        
        def watch(path, &block)
            
            path = File.expand_path(path)
            raise ArgumentError.new("expected #{path} to exists") if ! File.exists?(path)
            
            callback = Proc.new  do |stream, callbackInfo, numbEvents, paths, flags, ids|
                paths.cast!("*")
                dir = paths[0]
                modTime = File.new(dir).mtime.tv_sec
                
                changedFiles = Array.new
                Dir.foreach(dir) do |file|
                    next if file.start_with?(".")
                    header = File.join(dir, file)
                    mtime = File.new(header).mtime.tv_sec
                    diff = modTime - mtime
                    if diff <= 1.0 #we will consider files up to 2 seconds different in mod times as being "changed"
                        changedFiles << header
                    end
                end
                
                if changedFiles.count > 0
                    queue = Dispatch::Queue.concurrent
                    queue.async do
                        block.call(changedFiles)
                    end
                end
            end
            @stream = FSEventStreamCreate(KCFAllocatorDefault, callback, nil, [path], 
                                             KFSEventStreamEventIdSinceNow, 1.0, KFSEventStreamCreateFlagNone)
            queue = Dispatch::Queue.new("MotionGenerator.ProjectWatcher.WatchQueue")
            FSEventStreamSetDispatchQueue(@stream, queue.dispatch_object)
            FSEventStreamStart(@stream)
            
            self.run
            
        end
        
        def run
            Signal.trap("INT") do
                self.stop
                return
            end
            Dispatch::Queue.main.run
        end
        
        def stop
            FSEventStreamStop(@stream)
            FSEventStreamInvalidate(@stream)
        end
        
        
    end
    
end
=begin
pj = MotionGenerator::MGProjectWatcher.new
pj.watch("~/GitHub/RMNib/RMNib") do |changes|
    changes.each do |change|
        if File.extname(change) == ".h"
            puts "header changed: #{change}"
        end
    end
end

Signal.trap("INT") do 
    pj.stop
    return
end

Dispatch::Queue.main.run
=end