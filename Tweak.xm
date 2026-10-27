#import <CoreLocation/CoreLocation.h>

__attribute__((used)) static volatile double kLat = 37.32383276483316;
__attribute__((used)) static volatile double kLon = -122.1508491739245;

static CLLocation *fake(void) {
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(kLat, kLon)
                                         altitude:10 horizontalAccuracy:5 verticalAccuracy:5
                                        timestamp:[NSDate date]];
}

static void deliver(CLLocationManager *m) {
    id<CLLocationManagerDelegate> d = m.delegate;
    if ([d respondsToSelector:@selector(locationManager:didUpdateLocations:)])
        [d locationManager:m didUpdateLocations:@[fake()]];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static void grant(CLLocationManager *m) {
    id<CLLocationManagerDelegate> d = m.delegate;
    if ([d respondsToSelector:@selector(locationManager:didChangeAuthorizationStatus:)])
        [d locationManager:m didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    if ([d respondsToSelector:@selector(locationManagerDidChangeAuthorization:)])
        [d locationManagerDidChangeAuthorization:m];
}
#pragma clang diagnostic pop

%hook CLLocationManager
+ (CLAuthorizationStatus)authorizationStatus   { return kCLAuthorizationStatusAuthorizedAlways; }
+ (BOOL)locationServicesEnabled                { return YES; }
- (CLAuthorizationStatus)authorizationStatus   { return kCLAuthorizationStatusAuthorizedAlways; }
- (CLAccuracyAuthorization)accuracyAuthorization { return CLAccuracyAuthorizationFullAccuracy; }
- (CLLocation *)location                       { return fake(); }

- (void)requestWhenInUseAuthorization { grant(self); }
- (void)requestAlwaysAuthorization    { grant(self); }
- (void)requestLocation               { deliver(self); }

- (void)startUpdatingLocation {
    %orig;
    deliver(self);
}
%end
