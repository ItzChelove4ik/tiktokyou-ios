#import "BHIManager.h"
#import <Photos/Photos.h>

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

static UIViewController *topMostControllerInternal(void) {
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

@implementation BHIManager

+ (BOOL)hideAds { return [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_ads"]; }
+ (BOOL)hideLives { return [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_lives"]; }
+ (BOOL)hidePhotos { return [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_photos"]; }
+ (BOOL)hideStories { return [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_stories"]; }
+ (BOOL)hideSeries { return [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_series"]; }
+ (BOOL)hidePaid { return [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_paid"]; }
+ (BOOL)simpleMode { return [[NSUserDefaults standardUserDefaults] boolForKey:@"simple_mode"]; }
+ (BOOL)regionSpoofEnabled {
    // default YES: recommendations in Russia without VPN (base behavior preserved)
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:@"region_spoof_enabled"];
    return v ? [v boolValue] : YES;
}
+ (NSString *)selectedRegionISO {
    NSString *iso = [[NSUserDefaults standardUserDefaults] stringForKey:@"selected_region_iso"];
    return iso.length ? iso : @"KZ";
}
+ (BOOL)alwaysShowProgressBar { return [[NSUserDefaults standardUserDefaults] boolForKey:@"always_show_progress_bar"]; }
+ (BOOL)downloadButton {
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:@"download_button"];
    return v ? [v boolValue] : YES;
}
+ (BOOL)removeWatermark {
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:@"remove_watermark"];
    return v ? [v boolValue] : YES;
}
+ (BOOL)skipQualityPicker {
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:@"skip_quality_picker"];
    return v ? [v boolValue] : YES;
}
+ (BOOL)photoSave { return [[NSUserDefaults standardUserDefaults] boolForKey:@"tiktokyou_photo_save"]; }
+ (BOOL)antiBurnout { return [[NSUserDefaults standardUserDefaults] boolForKey:@"anti_burnout"]; }
+ (BOOL)antiBurnoutShowOnMain { return [[NSUserDefaults standardUserDefaults] boolForKey:@"anti_burnout_show_on_main"]; }
+ (BOOL)antiBurnoutEnableOnStart { return [[NSUserDefaults standardUserDefaults] boolForKey:@"anti_burnout_enable_on_start"]; }
+ (NSInteger)feedOverlayTransparency {
    NSInteger v = [[NSUserDefaults standardUserDefaults] integerForKey:@"feed_overlay_transparency"];
    return v > 0 ? v : 40;
}
+ (NSArray<NSString *> *)filterWords {
    return [[NSUserDefaults standardUserDefaults] stringArrayForKey:@"hide_by_words_filter"] ?: @[];
}
+ (long long)filterMinLikes { return [[NSUserDefaults standardUserDefaults] integerForKey:@"hide_by_likes"]; }
+ (long long)filterMinViews { return [[NSUserDefaults standardUserDefaults] integerForKey:@"hide_by_views"]; }
+ (long long)filterMinDate { return [[NSUserDefaults standardUserDefaults] integerForKey:@"hide_by_publish_date"]; }
+ (BOOL)uiHideEnabled { return [[NSUserDefaults standardUserDefaults] boolForKey:@"ui_hide_enabled"]; }
+ (NSDictionary *)uiHideRules {
    return [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ui_hide_rules"] ?: @{};
}
+ (BOOL)customColorsEnabled { return [[NSUserDefaults standardUserDefaults] boolForKey:@"custom_colors_enabled"]; }
+ (UIColor *)accentColor {
    NSInteger v = [[NSUserDefaults standardUserDefaults] integerForKey:@"accent_color"];
    if (!v) v = 0xFE2B54; // TikTok You pink
    return [UIColor colorWithRed:((v >> 16) & 0xFF) / 255.0
                           green:((v >> 8) & 0xFF) / 255.0
                            blue:(v & 0xFF) / 255.0
                           alpha:1.0];
}
+ (BOOL)rainbowModeEnabled { return [[NSUserDefaults standardUserDefaults] boolForKey:@"rainbow_mode_enabled"]; }
+ (NSString *)selectedFont { return [[NSUserDefaults standardUserDefaults] stringForKey:@"selected_font"] ?: @"default"; }
+ (BOOL)cleanShareLinks { return [[NSUserDefaults standardUserDefaults] boolForKey:@"clean_share_links"]; }
+ (BOOL)alwaysOpenSafari { return [[NSUserDefaults standardUserDefaults] boolForKey:@"openInBrowser"]; }
+ (BOOL)startupConsentAccepted { return [[NSUserDefaults standardUserDefaults] boolForKey:@"startup_consent_accepted"]; }
+ (BOOL)launchedFirstTime { return [[NSUserDefaults standardUserDefaults] boolForKey:@"launched_first_time"]; }

#pragma mark - media helpers (from base)

+ (void)showSaveVC:(id)item {
    UIActivityViewController *acVC = [[UIActivityViewController alloc] initWithActivityItems:item applicationActivities:nil];
    if (IS_IPAD) {
        acVC.popoverPresentationController.sourceView = topMostControllerInternal().view;
        acVC.popoverPresentationController.sourceRect = CGRectMake(topMostControllerInternal().view.bounds.size.width / 2.0, topMostControllerInternal().view.bounds.size.height / 2.0, 1.0, 1.0);
    }
    [topMostControllerInternal() presentViewController:acVC animated:true completion:nil];
}

+ (void)saveMedia:(id)newFilePath fileExtension:(id)fileextension {
    NSArray *imageExtensions = @[@"png", @"jpg", @"jpeg", @"gif", @"tiff", @"bmp", @"heif", @"heic", @"webp"];
    NSArray *videoExtensions = @[@"mp4", @"mov", @"avi", @"mkv", @"wmv", @"flv", @"webm", @"m4a"];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
        if ([videoExtensions containsObject:fileextension]) {
            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypeVideo fileURL:newFilePath options:options];
        } else if ([imageExtensions containsObject:fileextension]) {
            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto fileURL:newFilePath options:options];
        } else {
            NSLog(@"[TikTokYou] Unsupported file type: %@", fileextension);
        }
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"[TikTokYou] Media saved to Camera Roll.");
        } else {
            NSLog(@"[TikTokYou] Error saving media: %@", error);
            [HookLog log:@"saveMedia error: %@", error.localizedDescription];
        }
    }];
}

+ (void)cleanCache {
    NSArray *exts = @[@"mp4", @"png", @"jpeg", @"mp3", @"m4a", @"mov", @"tmp"];
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    for (NSString *dir in @[docs, NSTemporaryDirectory()]) {
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
        for (NSString *f in files) {
            NSString *ext = [[f pathExtension] lowercaseString];
            if ([exts containsObject:ext]) {
                [[NSFileManager defaultManager] removeItemAtPath:[dir stringByAppendingPathComponent:f] error:nil];
            }
        }
    }
}

+ (BOOL)isEmpty:(NSURL *)url {
    return [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil].count == 0;
}

@end

#pragma mark - HookLog

@implementation HookLog

+ (NSString *)path {
    static NSString *p = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        p = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:@"tiktokyou_hooklog.txt"] copy];
    });
    return p;
}

+ (void)log:(NSString *)fmt, ... {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *stamp = [[NSDate date] description];
        NSString *line = [NSString stringWithFormat:@"[%@] %@\n", stamp, msg];
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:HookLog.path];
        if (!fh) {
            [[NSFileManager defaultManager] createFileAtPath:HookLog.path
                contents:[line dataUsingEncoding:NSUTF8StringEncoding]
                attributes:nil];
        } else {
            [fh seekToEndOfFile];
            [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [fh closeFile];
        }
    });
}

+ (NSString *)contents {
    return [NSString stringWithContentsOfFile:HookLog.path encoding:NSUTF8StringEncoding error:nil] ?: @"Лог пуст.";
}

+ (void)clear {
    [[NSFileManager defaultManager] removeItemAtPath:HookLog.path error:nil];
}

@end
