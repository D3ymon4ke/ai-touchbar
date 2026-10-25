#import <Cocoa/Cocoa.h>
#import "AIUsageData.h"

@protocol TouchBarModalDelegate <NSObject>
- (void)touchBarDidRequestClose;
- (void)touchBarDidRequestRefresh;
@end

@interface TouchBarModalController : NSObject <NSTouchBarDelegate>

@property (nonatomic, strong, readonly) NSTouchBar *touchBar;
@property (nonatomic, weak) id<TouchBarModalDelegate> delegate;

- (instancetype)initWithSnapshot:(AIUsageSnapshot *)snapshot;
- (void)updateWithSnapshot:(AIUsageSnapshot *)snapshot;

@end
