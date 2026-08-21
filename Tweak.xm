#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

#define kFMFNDarwinNotifyFriends "_fmfn.notify.findmyfriends"
// #define kFMFNDarwinNotifyDevice "_fmfn.notify.findmydevice"


static NSString *_fmfn_lastCommandId = @"";
static NSDate *_fmfn_lastAlert = nil;

%group fmflocatord

%hook FindBaseServiceProvider

- (void)sendCurrentLocation:(id)location isFinished:(BOOL)finished forCmd:(NSDictionary *)command withReason:(long long)reason andAccuracyChange:(double)accuracy {
    %orig;

    NSString *commandId = [command objectForKey:@"id"];
    
    if (![commandId isEqualToString:_fmfn_lastCommandId] && (!_fmfn_lastAlert || [_fmfn_lastAlert timeIntervalSinceNow] < -60)) {
        _fmfn_lastCommandId = commandId;
        _fmfn_lastAlert = [NSDate date];

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR(kFMFNDarwinNotifyFriends),
            NULL, NULL, true
        );
    }
}

%end

%end



/*
%group findmydeviced

%hook FMDCommandHandlerLocate

- (void)_sendCurrentLocation:(id)location isFinished:(BOOL)finished forCmd:(NSDictionary *)command withReason:(long long)reason andAccuracyChange:(double)accuracy {
    %orig;

    NSString *commandId = [command objectForKey:@"id"];

    if (![commandId isEqualToString:_fmfn_lastCommandId] && (!_fmfn_lastAlert || [_fmfn_lastAlert timeIntervalSinceNow] < -60)) {
        _fmfn_lastCommandId = commandId;
        _fmfn_lastAlert = [NSDate date];

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR(kFMFNDarwinNotifyDevice),
            NULL, NULL, true
        );
    }
}

%end

%end // %group findmydeviced
*/



%group SpringBoard

static void _fmfn_showNotification(NSString *title, NSString *body) {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    content.sound = [UNNotificationSound defaultSound];

    [content setValue:@"com.apple.findmy" forKey:@"defaultActionBundleIdentifier"];

    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:content trigger:trigger];

    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
}

static void _fmfn_onFindMyFriendsNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _fmfn_showNotification(@"Find My (Notifications)", @"Someone requested your location via Find My");
}

/*
static void _fmfn_onFindMyDeviceNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _fmfn_showNotification(@"Find My (Notifications)", @"Someone triggered a locate command on this device");
}
*/

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), NULL,
        &_fmfn_onFindMyFriendsNotification,
        CFSTR(kFMFNDarwinNotifyFriends),
        NULL, CFNotificationSuspensionBehaviorDeliverImmediately
    );

    /*
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), NULL,
        &_fmfn_onFindMyDeviceNotification,
        CFSTR(kFMFNDarwinNotifyDevice),
        NULL, CFNotificationSuspensionBehaviorDeliverImmediately
    );
    */
}

%end

%end



%ctor {
    NSString *processName = [[NSProcessInfo processInfo] processName];

    if ([processName isEqualToString:@"SpringBoard"]) {
        %init(SpringBoard);
    } 
    else if ([processName isEqualToString:@"fmflocatord"]) {
        %init(fmflocatord);
    }
    /*
    else if ([processName isEqualToString:@"findmydeviced"]) {
        %init(findmydeviced);
    }
    */
}
