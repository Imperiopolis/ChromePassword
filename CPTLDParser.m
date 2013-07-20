#import "CPTLDParser.h"

#define CP_IANA_TLD_URL     (@"http://data.iana.org/TLD/tlds-alpha-by-domain.txt")
#define CP_IANA_TLD_FILE    (@"/Library/Application Support/ChromePassword/tlds-alpha-by-domain.txt")

@implementation CPTLDParser

- (id)init
{
    if ((self = [super init]))
    {
        [self loadTLDs];
    }

    return self;
}

- (void)dealloc
{
    [_cpTLDList release];
    _cpTLDList = nil;

    [super dealloc];
}

- (void)loadTLDs
{
    if (!_cpTLDList)
    {
        NSURL *url     = [NSURL URLWithString:CP_IANA_TLD_URL];
        NSString *text = [NSString stringWithContentsOfURL:url
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];

        if (!text)
        {
            text = [NSString stringWithContentsOfFile:CP_IANA_TLD_FILE
                                           encoding:NSUTF8StringEncoding
                                              error:nil];
        }

        if (text)
        {
            NSCharacterSet *newlines       = [NSCharacterSet newlineCharacterSet];
            NSMutableArray *lineComponents = [NSMutableArray arrayWithArray: [text componentsSeparatedByCharactersInSet:newlines]];

            [lineComponents removeLastObject];
            [lineComponents performSelector:@selector(removeFirstObject)];

            [_cpTLDList release];
            _cpTLDList = nil;
            _cpTLDList = [[lineComponents valueForKey:@"lowercaseString"] retain];
        }
    }
}

- (NSString*)queryStringFromURL: (NSURL*)url
{
    if (!url) { return nil; };

    [self loadTLDs];

    NSArray *urlComponents = [[[url host] lowercaseString] componentsSeparatedByString:@"."];

    NSMutableArray *sld = [NSMutableArray array];

    for (NSString *component in urlComponents)
    {
        if ([_cpTLDList containsObject:component])
        {
            break;
        }
        else
        {
            [sld addObject: component];
        }
    }
    NSLog(@"%@",sld);
    return [sld lastObject];
}

@end
