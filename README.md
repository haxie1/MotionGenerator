MotionGenerator
===============

Generates Ruby (RubyMotion/MacRuby) class files from Objective-C header files

MotionGenerator will take a OBJC header that looks something like:

	@interface MyViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
	@property (nonatomic, retain) IBOutlet UITableView *tableView;
	@property (nonatomic, reatain, readonly) NSString *foo;

	+ (void)myClassMethod;
	- (IBAction)someAction:(id)sender;
	- (void)somePublicMethod:(CustomClass *)theClass arg2:(id)bar;
	@end


and turns it into:

	class MyViewController < UIViewController #<UITableViewDataSource, UITableViewDelegate>
		attr_accessor :tableView
		attr_reader :foo
	
		def self.myClassMethod
		end
	
		def someAction(sender)
		end
	
		def somePublicMethod(theClass, arg2:bar)
		end
	
	end

How to use:
===============
* run it from the command line: motiongenerator /path/to/header.h /path/to/rubymotionapp/app
* require the OBJCHeaderToRubyGenerator.rb class in your project and go nuts.

Gotchas:
===============
* No support for header iVars (yet).
* protocols defined in the header are not supported (yet)
* could be (probably) bugs parsing the Objective-C method signatures

