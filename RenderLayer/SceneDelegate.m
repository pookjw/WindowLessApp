//
//  SceneDelegate.m
//  RenderLayer
//
//  Created by Jinwoo Kim on 8/22/25.
//

#import "SceneDelegate.h"
#include <TargetConditionals.h>
#include <objc/message.h>
#include <objc/runtime.h>

#if TARGET_OS_VISION
#include <dlfcn.h>

void *_rl_MRUIKitHandle;
void *_rl_CoreREHandle;
#endif

@interface SceneDelegate ()

@property (retain, nonatomic, readonly, direct) CALayer *layer;
@property (retain, nonatomic, nullable, direct) id caContext;
@end

@implementation SceneDelegate

#if TARGET_OS_VISION
+ (void)load {
    _rl_MRUIKitHandle = dlopen("/System/Library/PrivateFrameworks/MRUIKit.framework/MRUIKit", RTLD_NOW);
    _rl_CoreREHandle = dlopen("/System/Library/PrivateFrameworks/CoreRE.framework/CoreRE", RTLD_NOW);
}
#endif

- (instancetype)init {
    if (self = [super init]) {
        _layer = [[CALayer alloc] init];
        _layer.backgroundColor = UIColor.cyanColor.CGColor;
    }
    
    return self;
}

- (void)dealloc {
    [_window release];
    [_layer release];
    [_caContext release];
    [super dealloc];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
#if TARGET_OS_VISION
    id screen = ((id (*)(id, SEL))objc_msgSend)(scene, sel_registerName("screen"));
#else
    UIScreen *screen = ((id (*)(id, SEL))objc_msgSend)(scene, sel_registerName("screen"));
#endif
    id displayIdentity = ((id (*)(id, SEL))objc_msgSend)(screen, sel_registerName("displayIdentity"));
    unsigned int displayID = ((unsigned int (*)(id, SEL))objc_msgSend)(displayIdentity, sel_registerName("displayID"));
    
    NSMutableDictionary<NSString *, id> *options = [[NSMutableDictionary alloc] init];
    [options setObject:@(displayID) forKey:@"displayId"];
    
#if TARGET_OS_VISION
    NSDictionary<NSString *, id> *defaultOptions = ((id (*)(void *))dlsym(_rl_CoreREHandle, "RECAContextCreateDefaultOptions"))(NULL);
    [defaultOptions enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [options setObject:obj forKey:key];
    }];
    [defaultOptions release];
#endif
    
    id caContext = ((id (*)(Class, SEL, id))objc_msgSend)(objc_lookUpClass("CAContext"), sel_registerName("remoteContextWithOptions:"), options);
    [options release];
    assert(caContext != nil);
    self.caContext = caContext;
    
    ((void (*)(id, SEL, unsigned int))objc_msgSend)(caContext, sel_registerName("orderAbove:"), 0);
    ((void (*)(id, SEL, unsigned int))objc_msgSend)(caContext, sel_registerName("setCommitPriority:"), 1000);
    ((void (*)(id, SEL, id))objc_msgSend)(caContext, sel_registerName("setLayer:"), self.layer);
    
    id sceneLayer = ((id (*)(id, SEL, id))objc_msgSend)([objc_lookUpClass("FBSCAContextSceneLayer") alloc], sel_registerName("initWithCAContext:"), caContext);
    id fbsScene = ((id (*)(id, SEL))objc_msgSend)(scene, sel_registerName("_FBSScene"));
    ((void (*)(id, SEL, id))objc_msgSend)(fbsScene, sel_registerName("attachLayer:"), sceneLayer);
    [sceneLayer release];
    
    CGRect bounds = ((CGRect (*)(id, SEL))objc_msgSend)(scene, sel_registerName("bounds"));
    self.layer.frame = bounds;
    
#if TARGET_OS_VISION
    void *layerEntity = ((void * (*)(void))dlsym(_rl_CoreREHandle, "REEntityCreate"))();
    UIScene *hostingScene = ((id (*)(id, SEL))objc_msgSend)(scene, sel_registerName("_windowHostingScene"));
    void *reScene = ((void * (*)(id, SEL))objc_msgSend)(hostingScene, sel_registerName("reScene"));
    assert(reScene != NULL);
    
    ((void (*)(void *, void *))dlsym(_rl_CoreREHandle, "RESceneAddEntity"))(reScene, layerEntity);
    ((void (*)(void *))dlsym(_rl_MRUIKitHandle, "MRUIApplyBaseConfigurationToNewEntity"))(layerEntity);
    
    void *layerService = ((void * (*)(void))dlsym(_rl_MRUIKitHandle, "MRUIDefaultLayerService"))();
    void *caLayerComponent = ((void * (*)(void *, id, void *, void *))dlsym(_rl_CoreREHandle, "RECALayerServiceCreateRootComponent"))(layerService, caContext, layerEntity, NULL);
    
    ((void (*)(void *, BOOL))dlsym(_rl_CoreREHandle, "RECALayerComponentSetRespectsLayerTransform"))(caLayerComponent, NO);
    ((void (*)(void *, float))dlsym(_rl_CoreREHandle, "RECALayerComponentRootSetPointsPerMeter"))(caLayerComponent, 1360);
    ((void (*)(void *, BOOL))dlsym(_rl_CoreREHandle, "RECALayerComponentSetShouldSyncToRemotes"))(caLayerComponent, YES);
    ((void (*)(void *, BOOL))dlsym(_rl_CoreREHandle, "RECALayerClientComponentSetUpdatesMesh"))(caLayerComponent, NO);
    ((void (*)(void *, BOOL))dlsym(_rl_CoreREHandle, "RECALayerComponentSetUpdatesMaterial"))(caLayerComponent, NO);
    ((void (*)(void *, BOOL))dlsym(_rl_CoreREHandle, "RECALayerComponentSetUpdatesTexture"))(caLayerComponent, NO);
    ((void (*)(void *, BOOL))dlsym(_rl_CoreREHandle, "RECALayerComponentSetUpdatesClippingPrimitive"))(caLayerComponent, NO);
    
    void (*RERelease)(void *) = dlsym(_rl_CoreREHandle, "RERelease");
    RERelease(layerEntity);
    RERelease(caLayerComponent);
    
    [self.layer setValue:@{
        @"transform": @YES
    } forKeyPath:@"separatedOptions.updates"];
#endif
    [caContext release];
}

- (void)windowScene:(UIWindowScene *)windowScene didUpdateEffectiveGeometry:(UIWindowSceneGeometry *)previousEffectiveGeometry {
    CGRect bounds = ((CGRect (*)(id, SEL))objc_msgSend)(windowScene, sel_registerName("bounds"));
    self.layer.frame = bounds;
    
#if TARGET_OS_VISION
    [self.layer setValue:@{
        @"transform": @YES
    } forKeyPath:@"separatedOptions.updates"];
#endif
}

@end
