#import <Foundation/Foundation.h>


@interface BBBulletinRequest : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *sectionID;
@property (nonatomic, copy) NSString *bulletinID;
@property (nonatomic, copy) NSString *recordID;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, assign) BOOL clearable;
@end

@interface BBServer : NSObject
@property (nonatomic, readonly) dispatch_queue_t queue;
- (void)publishBulletin:(BBBulletinRequest *)bulletin destinations:(unsigned long long)destinations;
@end

static BBServer *_fmfn_bbServerInstance = nil;




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
    if (!_fmfn_bbServerInstance) return;

    BBBulletinRequest *bulletin = [[%c(BBBulletinRequest) alloc] init];
    bulletin.title = title;
    bulletin.message = body;
    bulletin.sectionID = @"com.apple.findmy";
    bulletin.date = [NSDate date];
    bulletin.clearable = YES;

    NSString *uuid = [[NSUUID UUID] UUIDString];
    bulletin.bulletinID = uuid;
    bulletin.recordID = uuid;

    dispatch_async(_fmfn_bbServerInstance.queue, ^{
        [_fmfn_bbServerInstance publishBulletin:bulletin destinations:15];
    });
}

static void _fmfn_onFindMyFriendsNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _fmfn_showNotification(@"Find My (Notifications)", @"Someone requested your location via Find My");
}

/*
static void _fmfn_onFindMyDeviceNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    _fmfn_showNotification(@"Find My (Notifications)", @"Someone triggered a locate command on this device");
}
*/

%hook BBServer
- (id)initWithQueue:(id)queue {
    _fmfn_bbServerInstance = %orig;
    return _fmfn_bbServerInstance;
}

- (id)initWithQueue:(id)queue dataProviderManager:(id)manager {
    _fmfn_bbServerInstance = %orig;
    return _fmfn_bbServerInstance;
}
%end

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
