#import "TouchBarModalController.h"

static NSTouchBarItemIdentifier const kItemClose   = @"com.antigravity.touchbar.close";
static NSTouchBarItemIdentifier const kItemModel   = @"com.antigravity.touchbar.model";
static NSTouchBarItemIdentifier const kItemGauge   = @"com.antigravity.touchbar.gauge";
static NSTouchBarItemIdentifier const kItemWeekly  = @"com.antigravity.touchbar.weekly";
static NSTouchBarItemIdentifier const kItemClaude  = @"com.antigravity.touchbar.claude";
static NSTouchBarItemIdentifier const kItemPlan    = @"com.antigravity.touchbar.plan";
static NSTouchBarItemIdentifier const kItemRefresh = @"com.antigravity.touchbar.refresh";

@interface TouchBarModalController ()
@property (nonatomic, strong) NSTouchBar *touchBar;
@property (nonatomic, strong) AIUsageSnapshot *snapshot;
@property (nonatomic, strong) NSButton *modelButton;
@property (nonatomic, strong) NSButton *gaugeButton;
@property (nonatomic, strong) NSButton *weeklyButton;
@property (nonatomic, strong) NSButton *claudeButton;
@property (nonatomic, strong) NSButton *planButton;
@end

@implementation TouchBarModalController

- (instancetype)initWithSnapshot:(AIUsageSnapshot *)snapshot {
    self = [super init];
    if (self) {
        _snapshot = snapshot;
        [self setupTouchBar];
    }
    return self;
}

- (void)setupTouchBar {
    NSTouchBar *tb = [[NSTouchBar alloc] init];
    tb.delegate = self;
    tb.defaultItemIdentifiers = @[
        kItemClose,
        NSTouchBarItemIdentifierFixedSpaceSmall,
        kItemModel,
        kItemGauge,
        kItemWeekly,
        kItemClaude,
        kItemPlan,
        NSTouchBarItemIdentifierFlexibleSpace,
        kItemRefresh
    ];
    self.touchBar = tb;
}

- (void)updateWithSnapshot:(AIUsageSnapshot *)snapshot {
    self.snapshot = snapshot;
    
    if (self.modelButton) {
        self.modelButton.title = [NSString stringWithFormat:@"🤖 %@", self.snapshot.modelName];
    }
    if (self.gaugeButton) {
        self.gaugeButton.title = [NSString stringWithFormat:@"⏱️ 5h: %.0f%%", self.snapshot.geminiFiveHour];
        if (self.snapshot.geminiFiveHour >= 50.0) {
            self.gaugeButton.bezelColor = [NSColor colorWithCalibratedRed:0.0 green:0.55 blue:0.4 alpha:0.8];
        } else if (self.snapshot.geminiFiveHour >= 20.0) {
            self.gaugeButton.bezelColor = [NSColor colorWithCalibratedRed:0.6 green:0.4 blue:0.1 alpha:0.8];
        } else {
            self.gaugeButton.bezelColor = [NSColor colorWithCalibratedRed:0.65 green:0.15 blue:0.15 alpha:0.8];
        }
    }
    if (self.weeklyButton) {
        self.weeklyButton.title = [NSString stringWithFormat:@"📅 Semanal: %.0f%%", self.snapshot.geminiWeekly];
    }
    if (self.claudeButton) {
        self.claudeButton.title = [NSString stringWithFormat:@"💎 Claude/GPT: %.0f%%", self.snapshot.claudeFiveHour];
    }
    if (self.planButton) {
        self.planButton.title = [NSString stringWithFormat:@"⭐️ %@", self.snapshot.planName];
    }
}

#pragma mark - NSTouchBarDelegate

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier {
    if ([identifier isEqualToString:kItemClose]) {
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSButton *btn = [NSButton buttonWithTitle:@"✕ Fechar" target:self action:@selector(handleClose:)];
        btn.bezelColor = [NSColor colorWithCalibratedRed:0.7 green:0.2 blue:0.2 alpha:0.8];
        item.view = btn;
        return item;
    }
    
    if ([identifier isEqualToString:kItemModel]) {
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSString *title = [NSString stringWithFormat:@"🤖 %@", self.snapshot.modelName];
        self.modelButton = [NSButton buttonWithTitle:title target:nil action:nil];
        self.modelButton.bezelColor = [NSColor colorWithCalibratedWhite:0.18 alpha:1.0];
        item.view = self.modelButton;
        return item;
    }
    
    if ([identifier isEqualToString:kItemGauge]) {
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSString *title = [NSString stringWithFormat:@"⏱️ 5h: %.0f%%", self.snapshot.geminiFiveHour];
        self.gaugeButton = [NSButton buttonWithTitle:title target:nil action:nil];
        if (self.snapshot.geminiFiveHour >= 50.0) {
            self.gaugeButton.bezelColor = [NSColor colorWithCalibratedRed:0.0 green:0.55 blue:0.4 alpha:0.8];
        } else if (self.snapshot.geminiFiveHour >= 20.0) {
            self.gaugeButton.bezelColor = [NSColor colorWithCalibratedRed:0.6 green:0.4 blue:0.1 alpha:0.8];
        } else {
            self.gaugeButton.bezelColor = [NSColor colorWithCalibratedRed:0.65 green:0.15 blue:0.15 alpha:0.8];
        }
        item.view = self.gaugeButton;
        return item;
    }
    
    if ([identifier isEqualToString:kItemWeekly]) {
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSString *title = [NSString stringWithFormat:@"📅 Semanal: %.0f%%", self.snapshot.geminiWeekly];
        self.weeklyButton = [NSButton buttonWithTitle:title target:nil action:nil];
        self.weeklyButton.bezelColor = [NSColor colorWithCalibratedWhite:0.18 alpha:1.0];
        item.view = self.weeklyButton;
        return item;
    }
    
    if ([identifier isEqualToString:kItemClaude]) {
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSString *title = [NSString stringWithFormat:@"💎 Claude/GPT: %.0f%%", self.snapshot.claudeFiveHour];
        self.claudeButton = [NSButton buttonWithTitle:title target:nil action:nil];
        self.claudeButton.bezelColor = [NSColor colorWithCalibratedWhite:0.18 alpha:1.0];
        item.view = self.claudeButton;
        return item;
    }
    
    if ([identifier isEqualToString:kItemPlan]) {
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSString *title = [NSString stringWithFormat:@"⭐️ %@", self.snapshot.planName];
        self.planButton = [NSButton buttonWithTitle:title target:nil action:nil];
        self.planButton.bezelColor = [NSColor colorWithCalibratedWhite:0.18 alpha:1.0];
        item.view = self.planButton;
        return item;
    }
    
    if ([identifier isEqualToString:kItemRefresh]) {
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
        NSButton *btn = [NSButton buttonWithTitle:@"🔄 Atualizar" target:self action:@selector(handleRefresh:)];
        btn.bezelColor = [NSColor colorWithCalibratedRed:0.1 green:0.35 blue:0.65 alpha:0.8];
        item.view = btn;
        return item;
    }
    
    return nil;
}

- (void)handleClose:(id)sender {
    if ([self.delegate respondsToSelector:@selector(touchBarDidRequestClose)]) {
        [self.delegate touchBarDidRequestClose];
    }
}

- (void)handleRefresh:(id)sender {
    if ([self.delegate respondsToSelector:@selector(touchBarDidRequestRefresh)]) {
        [self.delegate touchBarDidRequestRefresh];
    }
}

@end
