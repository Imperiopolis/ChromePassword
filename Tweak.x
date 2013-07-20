#import <UIKit/UIKit2.h>
#import <CoreFoundation/CFUserNotification.h>
#import <notify.h>
#import <CPTLDParser.h>

static CPTLDParser *_CPTLDParser;

@interface ToolsPopupMenuItem : NSObject
@property (assign, nonatomic) int tag;
+ (id)menuItem:(int)titleId title:(NSString *)title uiAutomationLabel:(NSString *)automationLabel command:(int)commandId;
@end

@class ToolsPopupTableViewController;

@protocol ToolsPopupTableDelegate <NSObject>
@optional
- (void)tappedBehindPopup:(ToolsPopupTableViewController *)popupTableViewController;
@end

@interface ToolsPopupTableViewController : UITableViewController
@property (assign,nonatomic) id<ToolsPopupTableDelegate> delegate;
@property (nonatomic,retain) NSMutableArray *menuItems;
@end

@interface BrowserViewController : UIViewController
- (void)loadJavascriptFromLocationBar:(NSString *)javascript;
@end


@interface Tab : NSObject
@property(readonly, nonatomic) NSString *urlDisplayString;
@end

@interface TabModel : NSObject
@property (assign, nonatomic) Tab *currentTab;
@end

@interface MainController : NSObject <UIApplicationDelegate>
@property (retain,nonatomic) TabModel *mainTabModel;
@property (assign,nonatomic) BrowserViewController *activeBVC;
@end

static inline id CPSetting(NSString *key)
{
  return [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.trappdesign.chromepassword.plist"] objectForKey:key];
}

%hook ToolsPopupTableViewController

- (void)setMenuItems:(NSArray *)array
{
  NSMutableArray *copy = [array mutableCopy];
  ToolsPopupMenuItem *menuItem = [%c(ToolsPopupMenuItem) menuItem:-3 title:@"1Password" uiAutomationLabel:@"1Password" command:-3];
  if (menuItem && [copy count] >= 3)
  {
    [copy insertObject:menuItem atIndex:3];
  }
  %orig(copy);
  [copy release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!_CPTLDParser)
  {
    _CPTLDParser = [[CPTLDParser alloc] init];
  }

  NSArray *menuItems = self.menuItems;
  ToolsPopupMenuItem *item = [menuItems objectAtIndex:indexPath.row];
  switch (item.tag)
  {
    case -3:
    {
      MainController *mc = (MainController *)UIApp.delegate;
      NSString *js = nil;
      if ([CPSetting(@"CPUse1Browser") boolValue])
      {
        js = @"window.location = 'op' + window.location.href ";
      }
      else
      {
        NSString *queryString = [_CPTLDParser queryStringFromURL: [NSURL URLWithString: mc.mainTabModel.currentTab.urlDisplayString]];
        NSLog(@"%@ %@", mc.mainTabModel.currentTab.urlDisplayString, queryString);
        js = [NSString stringWithFormat:@"window.location = 'onepassword://search/%@'",queryString];
      }
      [mc.activeBVC loadJavascriptFromLocationBar:js];
      id<ToolsPopupTableDelegate> delegate = self.delegate;
      if ([delegate respondsToSelector:@selector(tappedBehindPopup:)])
      {
        [delegate tappedBehindPopup:self];
      }
      break;
    }
      default:
        %orig();
  }
}

%end

static int unsupportedVersionCheck;

static void UnsupportedVersionCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
  uint64_t version = 0;
  notify_get_state(unsupportedVersionCheck, &version);
  CFUserNotificationCreate(kCFAllocatorDefault, 0, kCFUserNotificationPlainAlertLevel, NULL, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
    @"ChromePassword", (id)kCFUserNotificationAlertHeaderKey,
    [NSString stringWithFormat:@"Chrome M%d has not been tested with this version of ChromePassword. User at your own risk.", version], kCFUserNotificationAlertMessageKey,
    nil]);
}

%ctor {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if (objc_getClass("SpringBoard"))
  {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, UnsupportedVersionCallback, CFSTR("com.trappdesign.chromepassword.unsupportedversion"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    notify_register_check("com.trappdesign.chromepassword.unsupportedversion", &unsupportedVersionCheck);
  }
  else
  {
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFPropertyListRef version = CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("CFBundleShortVersionString")) ?: CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("CFBundleVersion")) ?: CFSTR("1");
    NSInteger versionValue = [(id)version integerValue];
    if ([(id)version intValue] > 28)
    {
      notify_register_check("com.trappdesign.chromepassword.unsupportedversion", &unsupportedVersionCheck);
      notify_set_state(unsupportedVersionCheck, versionValue);
      notify_post("com.trappdesign.chromepassword.unsupportedversion");
    }
    %init();
  }
  [pool drain];
}

