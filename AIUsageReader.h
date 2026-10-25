#import <Foundation/Foundation.h>
#import "AIUsageData.h"

@interface AIUsageReader : NSObject

@property (nonatomic, assign) NSInteger dailyLimit;

+ (instancetype)sharedReader;
- (AIUsageSnapshot *)fetchCurrentSnapshot;

@end
