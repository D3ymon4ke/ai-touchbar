#import <Foundation/Foundation.h>

@interface AIUsageSnapshot : NSObject

@property (nonatomic, copy) NSString *modelName;
@property (nonatomic, copy) NSString *planName;
@property (nonatomic, copy) NSString *userAccount;
@property (nonatomic, copy) NSString *userEmail;

// Cotas Reais do Antigravity IDE (gRPC / Language Server)
@property (nonatomic, assign) double geminiFiveHour;
@property (nonatomic, assign) double geminiWeekly;
@property (nonatomic, copy) NSString *geminiFiveHourDesc;
@property (nonatomic, copy) NSString *geminiWeeklyDesc;

@property (nonatomic, assign) double claudeFiveHour;
@property (nonatomic, assign) double claudeWeekly;

// Porcentagem primária exibida no botão
@property (nonatomic, assign) double remainingPercent;
@property (nonatomic, strong) NSDate *lastUpdated;

- (NSString *)formattedTouchBarText;
- (NSString *)formattedPercentageText;

@end
