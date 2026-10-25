#import <Cocoa/Cocoa.h>
#import "TouchBarModalController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, TouchBarModalDelegate>

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSCustomTouchBarItem *controlStripItem;
@property (nonatomic, strong) TouchBarModalController *modalController;
@property (nonatomic, strong) NSTimer *refreshTimer;

@end
