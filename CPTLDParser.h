#import <Foundation/Foundation.h>

@interface CPTLDParser : NSObject {
@private
	NSArray *_cpTLDList;
}

- (void)loadTLDs;
- (NSString*)queryStringFromURL: (NSURL*)url;

@end

