#import <Cocoa/Cocoa.h>
#import "AIUsageData.h"

@interface TouchBarGaugeView : NSView

@property (nonatomic, strong) AIUsageSnapshot *snapshot;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

- (instancetype)initWithSnapshot:(AIUsageSnapshot *)snapshot;
- (void)updateWithSnapshot:(AIUsageSnapshot *)snapshot;

@end
