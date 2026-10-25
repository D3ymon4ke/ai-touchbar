#import "AppDelegate.h"
#import "AIUsageReader.h"
#import "TouchBarGaugeView.h"
#import <dlfcn.h>

static NSTouchBarItemIdentifier const kControlStripId = @"com.antigravity.touchbar.aiusage";

@interface NSTouchBarItem (DFRPrivate)
+ (void)addSystemTrayItem:(NSTouchBarItem *)item;
+ (void)removeSystemTrayItem:(NSTouchBarItem *)item;
@end

@interface NSTouchBar (SystemModalPrivate)
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar;
+ (void)minimizeSystemModalTouchBar:(NSTouchBar *)touchBar;
@end

typedef void (*DFRElementSetControlStripPresenceForIdentifierFunc)(NSString *identifier, BOOL present);

@interface AppDelegate ()
@property (nonatomic, strong) AIUsageSnapshot *currentSnapshot;
@property (nonatomic, strong) TouchBarGaugeView *gaugeView;
@property (nonatomic, assign) DFRElementSetControlStripPresenceForIdentifierFunc setPresenceFunc;
@property (nonatomic, assign) BOOL isDisplayActive;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 1. Carregar função privada do DFRFoundation
    void *dfr = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation", RTLD_NOW);
    if (dfr) {
        self.setPresenceFunc = (DFRElementSetControlStripPresenceForIdentifierFunc)dlsym(dfr, "DFRElementSetControlStripPresenceForIdentifier");
    }
    
    // 2. Primeira leitura de dados da IA
    self.currentSnapshot = [[AIUsageReader sharedReader] fetchCurrentSnapshot];
    
    // 3. Configurar Touch Bar Modal Controller
    self.modalController = [[TouchBarModalController alloc] initWithSnapshot:self.currentSnapshot];
    self.modalController.delegate = self;
    
    // 4. Registrar observadores do NSWorkspace para acompanhar abertura/fechamento do Antigravity
    NSNotificationCenter *wsCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [wsCenter addObserver:self
                 selector:@selector(handleAppLaunched:)
                     name:NSWorkspaceDidLaunchApplicationNotification
                   object:nil];
    [wsCenter addObserver:self
                 selector:@selector(handleAppTerminated:)
                     name:NSWorkspaceDidTerminateApplicationNotification
                   object:nil];
    
    // 5. Verificar se o Antigravity já está aberto agora
    if ([self isAntigravityRunning]) {
        [self showOnTouchBarAndMenuBar];
    } else {
        NSLog(@"[AITouchBar] Antigravity IDE não está aberto no momento. Aguardando inicialização...");
        self.isDisplayActive = NO;
    }
}

- (BOOL)isAntigravityRunning {
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        NSString *bid = [app.bundleIdentifier lowercaseString];
        NSString *name = [app.localizedName lowercaseString];
        if ([bid containsString:@"antigravity"] || [name containsString:@"antigravity"]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isAntigravityApp:(NSRunningApplication *)app {
    NSString *bid = [app.bundleIdentifier lowercaseString];
    NSString *name = [app.localizedName lowercaseString];
    return ([bid containsString:@"antigravity"] || [name containsString:@"antigravity"]);
}

- (void)handleAppLaunched:(NSNotification *)notification {
    NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
    if ([self isAntigravityApp:app]) {
        NSLog(@"[AITouchBar] Antigravity IDE iniciado (%@). Ativando Touch Bar...", app.localizedName);
        // Aguarda 1.5s para os serviços internos e o Language Server inicializarem
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showOnTouchBarAndMenuBar];
        });
    }
}

- (void)handleAppTerminated:(NSNotification *)notification {
    NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
    if ([self isAntigravityApp:app]) {
        // Se ainda houver outra instância de Antigravity aberta, mantém
        if (![self isAntigravityRunning]) {
            NSLog(@"[AITouchBar] Antigravity IDE encerrou. Ocultando da Touch Bar e Menu Bar...");
            [self hideFromTouchBarAndMenuBar];
        }
    }
}

- (void)showOnTouchBarAndMenuBar {
    if (self.isDisplayActive) {
        [self refreshData];
        return;
    }
    self.isDisplayActive = YES;
    
    // Iniciar Menu Bar
    if (!self.statusItem) {
        [self setupMenuBarItem];
    } else {
        self.statusItem.visible = YES;
        [self updateMenuBarUI];
    }
    
    // Iniciar Control Strip na Touch Bar
    [self setupTouchBarControlStrip];
    
    // Iniciar timer de 10s
    [self.refreshTimer invalidate];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                         target:self
                                                       selector:@selector(refreshData)
                                                       userInfo:nil
                                                        repeats:YES];
    [self refreshData];
    NSLog(@"[AITouchBar] Ativado na Touch Bar com sucesso.");
}

- (void)hideFromTouchBarAndMenuBar {
    if (!self.isDisplayActive) return;
    self.isDisplayActive = NO;
    
    // Fechar modal se estiver aberto
    [self touchBarDidRequestClose];
    
    // Remover da Touch Bar
    if (self.setPresenceFunc) {
        self.setPresenceFunc(kControlStripId, NO);
    }
    if (self.controlStripItem && [NSTouchBarItem respondsToSelector:@selector(removeSystemTrayItem:)]) {
        [NSTouchBarItem removeSystemTrayItem:self.controlStripItem];
        self.controlStripItem = nil;
        self.gaugeView = nil;
    }
    
    // Ocultar da Menu Bar
    if (self.statusItem) {
        self.statusItem.visible = NO;
    }
    
    // Pausar timer
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)setupMenuBarItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.visible = YES;
    [self updateMenuBarUI];
}

- (void)updateMenuBarUI {
    if (!self.statusItem || !self.statusItem.isVisible) return;
    
    NSStatusBarButton *button = self.statusItem.button;
    if (button) {
        button.title = [NSString stringWithFormat:@"✨ %.0f%%", self.currentSnapshot.remainingPercent];
    }
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"AITouchBar"];
    
    // Título
    NSMenuItem *headerItem = [[NSMenuItem alloc] initWithTitle:@"🤖 AI TouchBar Monitor" action:nil keyEquivalent:@""];
    headerItem.enabled = NO;
    [menu addItem:headerItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // Plano
    NSString *planStr = [NSString stringWithFormat:@"Plano: %@", self.currentSnapshot.planName];
    NSMenuItem *planItem = [[NSMenuItem alloc] initWithTitle:planStr action:nil keyEquivalent:@""];
    planItem.enabled = NO;
    [menu addItem:planItem];
    
    // Modelo
    NSString *modelStr = [NSString stringWithFormat:@"Modelo: %@", self.currentSnapshot.modelName];
    NSMenuItem *modelItem = [[NSMenuItem alloc] initWithTitle:modelStr action:nil keyEquivalent:@""];
    modelItem.enabled = NO;
    [menu addItem:modelItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // Limite de 5 horas
    NSString *fiveHourStr = [NSString stringWithFormat:@"Limite de 5 Horas (Gemini): %.0f%%", self.currentSnapshot.geminiFiveHour];
    NSMenuItem *fiveHourItem = [[NSMenuItem alloc] initWithTitle:fiveHourStr action:nil keyEquivalent:@""];
    fiveHourItem.enabled = NO;
    [menu addItem:fiveHourItem];
    if (self.currentSnapshot.geminiFiveHourDesc.length > 0) {
        NSMenuItem *fiveDesc = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"  ↳ %@", self.currentSnapshot.geminiFiveHourDesc] action:nil keyEquivalent:@""];
        fiveDesc.enabled = NO;
        [menu addItem:fiveDesc];
    }
    
    // Limite Semanal
    NSString *weeklyStr = [NSString stringWithFormat:@"Limite Semanal (Gemini): %.0f%%", self.currentSnapshot.geminiWeekly];
    NSMenuItem *weeklyItem = [[NSMenuItem alloc] initWithTitle:weeklyStr action:nil keyEquivalent:@""];
    weeklyItem.enabled = NO;
    [menu addItem:weeklyItem];
    if (self.currentSnapshot.geminiWeeklyDesc.length > 0) {
        NSMenuItem *weekDesc = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"  ↳ %@", self.currentSnapshot.geminiWeeklyDesc] action:nil keyEquivalent:@""];
        weekDesc.enabled = NO;
        [menu addItem:weekDesc];
    }
    
    // Claude e GPT
    NSString *claudeStr = [NSString stringWithFormat:@"Modelos Claude e GPT: %.0f%% restante", self.currentSnapshot.claudeFiveHour];
    NSMenuItem *claudeItem = [[NSMenuItem alloc] initWithTitle:claudeStr action:nil keyEquivalent:@""];
    claudeItem.enabled = NO;
    [menu addItem:claudeItem];
    
    // Conta
    if (self.currentSnapshot.userEmail.length > 0) {
        [menu addItem:[NSMenuItem separatorItem]];
        NSString *userStr = [NSString stringWithFormat:@"Conta: %@", self.currentSnapshot.userEmail];
        NSMenuItem *userItem = [[NSMenuItem alloc] initWithTitle:userStr action:nil keyEquivalent:@""];
        userItem.enabled = NO;
        [menu addItem:userItem];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    // Ações
    NSMenuItem *openTouchBar = [[NSMenuItem alloc] initWithTitle:@"Abrir Painel na Touch Bar" action:@selector(handleOpenTouchBarModal:) keyEquivalent:@"t"];
    openTouchBar.target = self;
    [menu addItem:openTouchBar];
    
    NSMenuItem *refreshItem = [[NSMenuItem alloc] initWithTitle:@"Atualizar Dados Agora" action:@selector(refreshData) keyEquivalent:@"r"];
    refreshItem.target = self;
    [menu addItem:refreshItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Encerrar AITouchBar" action:@selector(handleQuit:) keyEquivalent:@"q"];
    quitItem.target = self;
    [menu addItem:quitItem];
    
    self.statusItem.menu = menu;
}

- (void)setupTouchBarControlStrip {
    if (![NSTouchBarItem respondsToSelector:@selector(addSystemTrayItem:)]) {
        NSLog(@"[AITouchBar] addSystemTrayItem não suportado neste sistema.");
        return;
    }
    
    if (self.controlStripItem) {
        if (self.setPresenceFunc) {
            self.setPresenceFunc(kControlStripId, YES);
        }
        return;
    }
    
    self.controlStripItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:kControlStripId];
    
    self.gaugeView = [[TouchBarGaugeView alloc] initWithSnapshot:self.currentSnapshot];
    self.gaugeView.target = self;
    self.gaugeView.action = @selector(handleOpenTouchBarModal:);
    
    self.controlStripItem.view = self.gaugeView;
    
    // Registrar na bandeja do sistema (Control Strip)
    [NSTouchBarItem addSystemTrayItem:self.controlStripItem];
    
    if (self.setPresenceFunc) {
        self.setPresenceFunc(kControlStripId, YES);
    }
}

- (void)handleOpenTouchBarModal:(id)sender {
    if (@available(macOS 10.14, *)) {
        [NSTouchBar presentSystemModalTouchBar:self.modalController.touchBar systemTrayItemIdentifier:kControlStripId];
    }
}

- (void)refreshData {
    if (!self.isDisplayActive) return;
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        AIUsageSnapshot *newSnapshot = [[AIUsageReader sharedReader] fetchCurrentSnapshot];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentSnapshot = newSnapshot;
            [self.gaugeView updateWithSnapshot:self.currentSnapshot];
            [self.modalController updateWithSnapshot:self.currentSnapshot];
            [self updateMenuBarUI];
        });
    });
}

#pragma mark - TouchBarModalDelegate

- (void)touchBarDidRequestClose {
    if (@available(macOS 10.14, *)) {
        [NSTouchBar minimizeSystemModalTouchBar:self.modalController.touchBar];
    }
}

- (void)touchBarDidRequestRefresh {
    [self refreshData];
}

- (void)handleQuit:(id)sender {
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self hideFromTouchBarAndMenuBar];
}

@end
