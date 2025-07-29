//
//  LayerSceneDelegate.m
//  MyApp
//
//  Created by Jinwoo Kim on 7/27/25.
//

#import "LayerSceneDelegate.h"
#include <objc/message.h>
#include <objc/runtime.h>

struct __attribute__((aligned(32))) UIContextBindingDescription {
    id displayIdentity;
    BOOL unknown;
    BOOL ignoresHitTest;
    BOOL shouldCreateContextAsSecure;
    BOOL shouldUseRemoteContext;
    BOOL alwaysGetsContexts;
    BOOL isWindowServerHostingManaged;
    BOOL keepContextInBackground;
    BOOL allowsOcclusionDetectionOverride;
    BOOL wantsSuperlayerSecurityAnalysis;
};

CA_EXTERN unsigned long long const CAInvalidRenderId;

@interface MyLayer : CALayer
@end
@implementation MyLayer
- (void)layoutSublayers {
    [super layoutSublayers];
}
- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
}
@end

@interface LayerSceneDelegate ()
@property (weak, nonatomic, setter=_setBoundContext:) id _boundContext;
@property (weak, nonatomic, setter=_setContextBinder:) id _contextBinder;
@property (retain, nonatomic, nullable) MyLayer *layer;
@property (weak, nonatomic, nullable) UIWindowScene *windowScene;
@end

@implementation LayerSceneDelegate

+ (void)load {
    Protocol * _Nullable _UIContextBindable = NSProtocolFromString(@"_UIContextBindable");
    if (_UIContextBindable != NULL) {
        assert(class_addProtocol(self, _UIContextBindable));
    }
}

- (void)dealloc {
    [_window release];
    [_layer release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"effectiveGeometry"]) {
        [self effectiveGeometryDidChange:object];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.windowScene = windowScene;
    
    [windowScene addObserver:self forKeyPath:@"effectiveGeometry" options:NSKeyValueObservingOptionNew context:NULL];
    
    [_layer release];
    _layer = [[MyLayer alloc] init];
    
    id contextBinder = ((id (*)(id, SEL))objc_msgSend)(windowScene, sel_registerName("_contextBinder"));
    id substrate = ((id (*)(id, SEL))objc_msgSend)(contextBinder, sel_registerName("substrate"));
    id context = ((id (*)(Class, SEL, id, id))objc_msgSend)(objc_lookUpClass("_UIContextBinder"), sel_registerName("createContextForBindable:withSubstrate:"), self, substrate);
    ((void (*)(id, SEL, id))objc_msgSend)(substrate, sel_registerName("attachContext:"), context);
    
    _layer.frame = ((CGRect (*)(id, SEL))objc_msgSend)(windowScene, sel_registerName("bounds"));
    _layer.hidden = NO;
    _layer.backgroundColor = UIColor.cyanColor.CGColor;
}

- (void)effectiveGeometryDidChange:(UIWindowScene *)sender {
    _layer.frame = ((CGRect (*)(id, SEL))objc_msgSend)(sender, sel_registerName("bounds"));
    [_layer setNeedsLayout];
}

- (struct UIContextBindingDescription)_bindingDescription {
    id screen = ((id (*)(id, SEL))objc_msgSend)(self.windowScene, sel_registerName("screen"));
    id displayIdentity = ((id (*)(id, SEL))objc_msgSend)(screen, sel_registerName("displayIdentity"));
    
    struct UIContextBindingDescription description = {
        .displayIdentity = displayIdentity,
        .ignoresHitTest = NO,
        .shouldCreateContextAsSecure = YES,
        .shouldUseRemoteContext = YES,
        .alwaysGetsContexts = NO,
        .isWindowServerHostingManaged = YES,
        .keepContextInBackground = NO,
        .allowsOcclusionDetectionOverride = NO,
        .wantsSuperlayerSecurityAnalysis = NO
    };
    
    return description;
}

- (NSDictionary *)_contextOptionsWithInitialOptions:(NSDictionary *)options {
    return options;
}

- (CGFloat)_bindableLevel {
    return UIWindowLevelNormal;
}

- (CALayer *)_bindingLayer {
    return _layer;
}

- (BOOL)_isVisible {
    abort();
    return NO;
}

@end

