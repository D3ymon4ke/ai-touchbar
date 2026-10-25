#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        // Executar como acessório em segundo plano (sem ícone no dock se preferir, ou app normal)
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        
        [app run];
    }
    return 0;
}
