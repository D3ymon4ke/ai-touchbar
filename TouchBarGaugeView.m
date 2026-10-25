#import "TouchBarGaugeView.h"

@interface TouchBarGaugeView ()
@property (nonatomic, assign) BOOL isHighlighted;
@end

@implementation TouchBarGaugeView

- (instancetype)initWithSnapshot:(AIUsageSnapshot *)snapshot {
    // A largura ideal para o slot do Control Strip no macOS é entre 64 e 68 pontos
    NSRect frame = NSMakeRect(0, 0, 68, 30);
    self = [super initWithFrame:frame];
    if (self) {
        _snapshot = snapshot;
        _isHighlighted = NO;
        self.allowedTouchTypes = NSTouchTypeMaskDirect;
    }
    return self;
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(68, 30);
}

- (BOOL)acceptsTouchEvents {
    return YES;
}

- (void)updateWithSnapshot:(AIUsageSnapshot *)snapshot {
    self.snapshot = snapshot;
    [self setNeedsDisplay:YES];
}

#pragma mark - Touch & Mouse Events

- (void)mouseDown:(NSEvent *)event {
    self.isHighlighted = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event {
    self.isHighlighted = NO;
    [self setNeedsDisplay:YES];
    
    NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
    if (NSPointInRect(location, self.bounds)) {
        [self triggerAction];
    }
}

- (void)touchesBeganWithEvent:(NSEvent *)event {
    self.isHighlighted = YES;
    [self setNeedsDisplay:YES];
}

- (void)touchesEndedWithEvent:(NSEvent *)event {
    self.isHighlighted = NO;
    [self setNeedsDisplay:YES];
    [self triggerAction];
}

- (void)touchesCancelledWithEvent:(NSEvent *)event {
    self.isHighlighted = NO;
    [self setNeedsDisplay:YES];
}

- (void)triggerAction {
    if (self.target && self.action && [self.target respondsToSelector:self.action]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:self];
        #pragma clang diagnostic pop
    }
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSRect bounds = self.bounds;
    NSRect pillRect = NSInsetRect(bounds, 1.5, 1.5);
    
    // 1. Fundo do Botão (estilo nativo Apple Touch Bar)
    NSBezierPath *bgPath = [NSBezierPath bezierPathWithRoundedRect:pillRect xRadius:6 yRadius:6];
    if (self.isHighlighted) {
        [[NSColor colorWithCalibratedWhite:0.28 alpha:1.0] setFill];
    } else {
        [[NSColor colorWithCalibratedWhite:0.14 alpha:1.0] setFill];
    }
    [bgPath fill];
    
    // Borda sutil
    [[NSColor colorWithCalibratedWhite:0.32 alpha:0.6] setStroke];
    bgPath.lineWidth = 1.0;
    [bgPath stroke];
    
    // 2. Texto Principal: "✨ 60%" (perfeitamente centralizado e visível no slot)
    NSString *text = [NSString stringWithFormat:@"✨ %.0f%%", self.snapshot.remainingPercent];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11.5 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.96 alpha:1.0],
        NSParagraphStyleAttributeName: style
    };
    
    // Desenhar texto ligeiramente acima da mini barra de progresso
    NSRect textRect = NSMakeRect(pillRect.origin.x, pillRect.origin.y + 7.5, pillRect.size.width, 16);
    [text drawInRect:textRect withAttributes:attrs];
    
    // 3. Mini Barra de Progresso na parte inferior do botão
    CGFloat trackX = pillRect.origin.x + 8;
    CGFloat trackY = pillRect.origin.y + 3.5;
    CGFloat trackW = pillRect.size.width - 16;
    CGFloat trackH = 3.0;
    
    NSRect trackRect = NSMakeRect(trackX, trackY, trackW, trackH);
    NSBezierPath *trackPath = [NSBezierPath bezierPathWithRoundedRect:trackRect xRadius:1.5 yRadius:1.5];
    [[NSColor colorWithCalibratedWhite:0.25 alpha:0.8] setFill];
    [trackPath fill];
    
    // Preenchimento gradiente conforme a cota restante
    CGFloat ratio = self.snapshot.remainingPercent / 100.0;
    if (ratio < 0.0) ratio = 0.0;
    if (ratio > 1.0) ratio = 1.0;
    
    CGFloat fillW = trackW * ratio;
    if (fillW > 0) {
        NSRect fillRect = NSMakeRect(trackX, trackY, fillW, trackH);
        NSBezierPath *fillPath = [NSBezierPath bezierPathWithRoundedRect:fillRect xRadius:1.5 yRadius:1.5];
        
        NSColor *color1;
        NSColor *color2;
        if (self.snapshot.remainingPercent >= 50.0) {
            // Verde / Ciano vibrante
            color1 = [NSColor colorWithCalibratedRed:0.0 green:0.88 blue:0.65 alpha:1.0];
            color2 = [NSColor colorWithCalibratedRed:0.0 green:0.75 blue:0.98 alpha:1.0];
        } else if (self.snapshot.remainingPercent >= 20.0) {
            // Âmbar / Laranja
            color1 = [NSColor colorWithCalibratedRed:0.98 green:0.75 blue:0.18 alpha:1.0];
            color2 = [NSColor colorWithCalibratedRed:0.95 green:0.55 blue:0.10 alpha:1.0];
        } else {
            // Vermelho / Coral
            color1 = [NSColor colorWithCalibratedRed:0.95 green:0.25 blue:0.25 alpha:1.0];
            color2 = [NSColor colorWithCalibratedRed:0.85 green:0.15 blue:0.35 alpha:1.0];
        }
        
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:color1 endingColor:color2];
        [gradient drawInBezierPath:fillPath angle:0.0];
    }
}

@end
