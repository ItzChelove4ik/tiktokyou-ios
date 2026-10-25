#import "TikTokHeaders.h"
#import "BHIManager.h"
#import "YouSettingsViewController.h"
#import "YouFloatingHub.h"
#import <objc/runtime.h>

NSArray *jailbreakPaths;

// ============================================================
// TikTok You (iOS port) — hooks
// Дизайн: каждый %group оборачивает фичу; в %ctor класс проверяется
// через objc_getClass — отсутствующий класс = фича тихо off + лог.
// ============================================================

static BOOL classExistsNamed(NSString *name) {
    return objc_getClass(name.UTF8String) != NULL;
}

// Централизованный фильтр контента: применяется к модели aweme в фиде.
static BOOL shouldFilterAweme(id model) {
    if (!model) return NO;
    @try {
        // content filters
        long long likes = 0, views = 0, date = 0;
        id stats = [model valueForKey:@"statistics"];
        if (stats) {
            id d = [stats valueForKey:@"diggCount"]; if ([d respondsToSelector:@selector(longLongValue)]) likes = [d longLongValue];
            id p = [stats valueForKey:@"playCount"]; if ([p respondsToSelector:@selector(longLongValue)]) views = [p longLongValue];
        }
        id ct = [model valueForKey:@"createTime"];
        if ([ct respondsToSelector:@selector(longLongValue)]) date = [ct longLongValue];
        if ([BHIManager filterMinLikes] > 0 && likes < [BHIManager filterMinLikes]) return YES;
        if ([BHIManager filterMinViews] > 0 && views < [BHIManager filterMinViews]) return YES;
        if ([BHIManager filterMinDate] > 0 && date > 0 && date < [BHIManager filterMinDate]) return YES;
        NSArray *words = [BHIManager filterWords];
        if (words.count) {
            NSString *desc = [model valueForKey:@"desc"] ?: @"";
            id textExtra = [model valueForKey:@"textExtra"];
            NSString *hashtags = @"";
            if ([textExtra respondsToSelector:@selector(componentsJoinedByString:)]) {
                // array of dicts with hashtagName
                NSMutableString *hs = [NSMutableString string];
                for (id te in (NSArray *)textExtra) {
                    id hn = [te valueForKey:@"hashtagName"];
                    if ([hn isKindOfClass:[NSString class]]) { [hs appendFormat:@"%@ ", hn]; }
                }
                hashtags = hs;
            }
            NSString *hay = [NSString stringWithFormat:@"%@ %@", desc, hashtags];
            for (NSString *w in words) {
                if (w.length && [hay rangeOfString:w options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    return YES;
                }
            }
        }
        // hide photos / series / paid / stories
        if ([BHIManager hidePhotos]) {
            id photoAlbum = [model valueForKey:@"photoAlbum"];
            id awemeType = [model valueForKey:@"awemeType"];
            NSInteger type = [awemeType respondsToSelector:@selector(integerValue)] ? [awemeType integerValue] : 0;
            if ((photoAlbum && [photoAlbum respondsToSelector:@selector(count)] && [(NSArray *)photoAlbum count] > 0) || type == 68 || type == 150) return YES;
        }
        if ([BHIManager hideSeries]) {
            id series = [model valueForKey:@"seriesInfo"];
            id drama = [model valueForKey:@"dramaInfo"];
            if (series || drama) return YES;
        }
        if ([BHIManager hidePaid]) {
            id commerce = [model valueForKey:@"commerceInfo"];
            if (commerce && [commerce respondsToSelector:@selector(hash)] && [commerce hash] != 0) {
                // non-empty commerce container — heuristics
                id infos = [commerce valueForKey:@"infos"];
                if ([infos respondsToSelector:@selector(count)] && [(NSArray *)infos count] > 0) return YES;
            }
        }
        if ([BHIManager hideStories]) {
            id story = [model valueForKey:@"story"];
            if (story) {
                id sinfo = [story valueForKey:@"storyInfo"];
                if (sinfo && [sinfo respondsToSelector:@selector(count)] && [(NSArray *)sinfo count] > 0) return YES;
            }
        }
    } @catch (NSException *e) {
        [HookLog log:@"filter aweme exception: %@", e];
    }
    return NO;
}

// ============================================================
// Группа: Реклама + фильтры контента (AWEAwemeModel)
// ============================================================
%group TikTokYouFeedFilter
%hook AWEAwemeModel
- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    id orig = %orig;
    if (orig && [BHIManager hideAds] && [orig isAds]) return nil;
    if (orig && shouldFilterAweme(orig)) return nil;
    return orig;
}
- (id)init {
    id orig = %orig;
    if (orig && [BHIManager hideAds] && [orig isAds]) return nil;
    if (orig && shouldFilterAweme(orig)) return nil;
    return orig;
}
- (BOOL)progressBarDraggable {
    if ([BHIManager alwaysShowProgressBar]) return YES;
    return %orig;
}
- (BOOL)progressBarVisible {
    if ([BHIManager alwaysShowProgressBar]) return YES;
    return %orig;
}
%end

%end // group

// AWEAwemeACLItem: watermark removal (outside group — Logos %orig quirk)
%hook AWEAwemeACLItem
- (void)setWatermarkType:(NSUInteger)arg1 {
    if ([BHIManager removeWatermark]) {
        %orig(1);
    } else {
        %orig;
    }
}
- (NSUInteger)watermarkType {
    if ([BHIManager removeWatermark]) return 1;
    return %orig;
}
%end

// ============================================================
// Группа: Трансляции off
// ============================================================
%group TikTokYouLives
%hook AWEAwemeModel
- (void)live_callInitWithDictyCategoryMethod:(id)arg1 {
    if (![BHIManager hideLives]) {
        %orig;
    }
}
+ (id)liveStreamURLJSONTransformer {
    if ([BHIManager hideLives]) return nil;
    return %orig;
}
+ (id)relatedLiveJSONTransformer {
    if ([BHIManager hideLives]) return nil;
    return %orig;
}
+ (id)rawModelFromLiveRoomModel:(id)arg1 {
    if ([BHIManager hideLives]) return nil;
    return %orig;
}
+ (id)aweLiveRoom_subModelPropertyKey {
    if ([BHIManager hideLives]) return nil;
    return %orig;
}
%end
%hook AWELiveFeedEntranceView
- (void)didMoveToWindow {
    if ([BHIManager hideLives]) { self.hidden = YES; return; }
    %orig;
}
%end
%end // group

// ============================================================
// Группа: Регион (полный блок из базы; дефолт KZ сохранён)
// ============================================================
%group TikTokYouRegion
%hook CTCarrier
- (NSString *)mobileCountryCode {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [RegionInfo currentRegion][@"mcc"];
    return %orig;
}
- (void)setIsoCountryCode:(NSString *)arg1 {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return %orig([RegionInfo currentRegion][@"code"]);
    return %orig(arg1);
}
- (NSString *)isoCountryCode {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [RegionInfo currentRegion][@"code"];
    return %orig;
}
- (NSString *)mobileNetworkCode {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [RegionInfo currentRegion][@"mnc"];
    return %orig;
}
%end

%hook TTKStoreRegionService
- (id)storeRegion {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [[RegionInfo currentRegion][@"code"] lowercaseString];
    return %orig;
}
- (id)getStoreRegion {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [[RegionInfo currentRegion][@"code"] lowercaseString];
    return %orig;
}
- (void)setStoreRegion:(id)arg1 {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return %orig([[RegionInfo currentRegion][@"code"] lowercaseString]);
    return %orig(arg1);
}
%end

%hook TIKTOKRegionManager
+ (NSString *)systemRegion {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [RegionInfo currentRegion][@"code"];
    return %orig;
}
+ (id)region {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [RegionInfo currentRegion][@"code"];
    return %orig;
}
+ (id)mccmnc {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [NSString stringWithFormat:@"%@%@", [RegionInfo currentRegion][@"mcc"], [RegionInfo currentRegion][@"mnc"]];
    return %orig;
}
+ (id)storeRegion {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [RegionInfo currentRegion][@"code"];
    return %orig;
}
+ (id)currentRegionV2 {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [RegionInfo currentRegion][@"code"];
    return %orig;
}
+ (id)localRegion {
    if ([BHIManager regionSpoofEnabled] && [RegionInfo currentRegion]) return [RegionInfo currentRegion][@"code"];
    return %orig;
}
%end
%end // group

// ============================================================
// Группа: Ссылки в Safari (Spark)
// ============================================================
%group TikTokYouSafari
%hook SparkViewController
- (void)loadURL:(id)arg1 withString:(id)arg2 {
    if ([BHIManager alwaysOpenSafari]) {
        if ([arg2 isKindOfClass:[NSString class]] && [(NSString *)arg2 hasPrefix:@"http"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:arg2] options:@{} completionHandler:nil];
            return;
        }
    }
    %orig;
}
%end
%end // group

// ============================================================
// Группа: пункт меню в TikTok Settings + чистка share-ссылок
// ============================================================
%group TikTokYouSettingsEntry
%hook TTKSettingsBaseCellPlugin
- (void)didSelectItemAtIndex:(NSInteger)index {
    if ([self.itemModel.identifier isEqualToString:@"ttmod_settings"]) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[YouSettingsViewController alloc] init]];
        [topMostController() presentViewController:nav animated:true completion:nil];
    } else {
        return %orig;
    }
}
%end

%hook AWESettingsNormalSectionViewModel
- (void)viewDidLoad {
    %orig;
    if ([self.sectionIdentifier isEqualToString:@"account"]) {
        TTKSettingsBaseCellPlugin *cell = [[%c(TTKSettingsBaseCellPlugin) alloc] initWithPluginContext:self.context];
        AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] initWithIdentifier:@"ttmod_settings"];
        [item setTitle:@"Настройки TikTok You"];
        [item setDetail:@"Мод-меню TikTok You"];
        [item setIconImage:[UIImage systemImageNamed:@"flame.fill"]];
        [item setType:99];
        [cell setItemModel:item];
        [self insertModel:cell atIndex:0 animated:true];
    }
}
%end

// чистка трекинг-параметров при копировании ссылки
%hook UIPasteboard
- (void)setString:(NSString *)stringValue {
    if ([BHIManager cleanShareLinks] && [stringValue hasPrefix:@"http"]) {
        NSURL *url = [NSURL URLWithString:stringValue];
        if (url) {
            NSURLComponents *c = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            NSMutableArray *kept = [NSMutableArray array];
            for (NSURLQueryItem *qi in c.queryItems ?: @[]) {
                NSString *n = qi.name.lowercaseString;
                if ([n hasPrefix:@"utm_"] || [n hasPrefix:@"share_"] || [n hasPrefix:@"enter_"] ||
                    [n isEqualToString:@"u_code"] || [n isEqualToString:@"tt_from"] ||
                    [n isEqualToString:@"source"] || [n isEqualToString:@"timestamp"] ||
                    [n isEqualToString:@"user_id"] || [n isEqualToString:@"ug_btm"] ||
                    [n hasPrefix:@"share_link"] || [n hasPrefix:@"share_app"] || [n hasPrefix:@"share_item"]) {
                    continue;
                }
                [kept addObject:qi];
            }
            c.queryItems = kept.count ? kept : nil;
            NSString *clean = c.URL.absoluteString;
            %orig(clean);
            return;
        }
    }
    %orig;
}
%end
%end // group

// ============================================================
// Группа: Плавающий хаб + запуск (AppDelegate)
// ============================================================
%group TikTokYouApp
%hook AppDelegate
- (_Bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(id)arg2 {
    %orig;
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if (![d objectForKey:@"launched_first_time"]) {
        // TikTok You defaults
        [d setBool:YES forKey:@"launched_first_time"];
        [d setBool:YES forKey:@"hide_ads"];
        [d setBool:YES forKey:@"download_button"];
        [d setBool:YES forKey:@"remove_watermark"];
        [d setBool:YES forKey:@"skip_quality_picker"];
        // region default: ON + KZ (base behavior — recommendations in Russia without VPN)
        [d setBool:YES forKey:@"region_spoof_enabled"];
        [d setObject:@"KZ" forKey:@"selected_region_iso"];
    }
    [BHIManager cleanCache];
    // floating hub
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[YouFloatingHub shared] show];
    });
    return true;
}
%end
%end // group

// ============================================================
// Группа: анти-детект джейлбрейка (из базы, не трогать)
// ============================================================
%group TikTokYouJBBypass
%hook NSFileManager
-(BOOL)fileExistsAtPath:(id)arg1 {
    for (NSString *file in jailbreakPaths) { if ([arg1 isEqualToString:file]) return NO; }
    return %orig;
}
-(BOOL)fileExistsAtPath:(id)arg1 isDirectory:(BOOL*)arg2 {
    for (NSString *file in jailbreakPaths) { if ([arg1 isEqualToString:file]) return NO; }
    return %orig;
}
%end
%hook BDADeviceHelper
+(bool)isJailBroken { return NO; }
%end
%hook UIDevice
+(bool)btd_isJailBroken { return NO; }
%end
%hook TTInstallUtil
+(bool)isJailBroken { return NO; }
%end
%hook AppsFlyerUtils
+(bool)isJailbrokenWithSkipAdvancedJailbreakValidation:(bool)arg2 { return NO; }
%end
%hook PIPOIAPStoreManager
-(bool)_pipo_isJailBrokenDeviceWithProductID:(id)arg2 orderID:(id)arg3 { return NO; }
%end
%hook IESLiveDeviceInfo
+(bool)isJailBroken { return NO; }
%end
%hook PIPOStoreKitHelper
-(bool)isJailBroken { return NO; }
%end
%hook BDInstallNetworkUtility
+(bool)isJailBroken { return NO; }
%end
%hook TTAdSplashDeviceHelper
+(bool)isJailBroken { return NO; }
%end
%hook GULAppEnvironmentUtil
+(bool)isFromAppStore { return YES; }
+(bool)isAppStoreReceiptSandbox { return NO; }
+(bool)isAppExtension { return YES; }
%end
%hook FBSDKAppEventsUtility
+(bool)isDebugBuild { return NO; }
%end
%hook AWEAPMManager
+(id)signInfo { return @"AppStore"; }
%end
%hook NSBundle
-(id)pathForResource:(id)arg1 ofType:(id)arg2 {
    if ([arg2 isEqualToString:@"mobileprovision"]) return nil;
    return %orig;
}
%end
%hook AWESecurity
- (void)resetCollectMode { return; }
%end
%hook MSManagerOV
- (id)setMode { return (id (^)(id)) ^{}; }
%end
%hook MSConfigOV
- (id)setMode { return (id (^)(id)) ^{}; }
%end
%end // group

// ============================================================
// %ctor
// ============================================================
__attribute__((constructor)) static void BHTikTokPhase0Ctor(void) {
    // PHASE-0 DIAGNOSTIC: no hooks installed at all, only a log line.
    // If app crashes here still -> problem is dylib load/substrate, not hooking.
    [HookLog log:@"PHASE0: dylib loaded, no hooks installed"];
}
