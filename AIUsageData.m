#import "AIUsageData.h"

@implementation AIUsageSnapshot

- (instancetype)init {
    self = [super init];
    if (self) {
        _modelName = @"Gemini 3.8 Flash";
        _planName = @"Google AI Pro";
        _userAccount = @"Marina Nobre";
        _userEmail = @"";
        _geminiFiveHour = 100.0;
        _geminiWeekly = 100.0;
        _geminiFiveHourDesc = @"";
        _geminiWeeklyDesc = @"";
        _claudeFiveHour = 100.0;
        _claudeWeekly = 100.0;
        _remainingPercent = 100.0;
        _lastUpdated = [NSDate date];
    }
    return self;
}

- (NSString *)formattedTouchBarText {
    return [NSString stringWithFormat:@"✨ %.0f%%", self.remainingPercent];
}

- (NSString *)formattedPercentageText {
    return [NSString stringWithFormat:@"%.0f%%", self.remainingPercent];
}

@end
