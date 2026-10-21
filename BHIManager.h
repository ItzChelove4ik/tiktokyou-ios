#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BHIManager: NSObject
// TikTok You settings (keys mirror Android ttmod_settings prefs)
+ (BOOL)hideAds;                 // hide_ads
+ (BOOL)hideLives;               // hide_lives
+ (BOOL)hidePhotos;              // hide_photos
+ (BOOL)hideStories;             // hide_stories
+ (BOOL)hideSeries;              // hide_series
+ (BOOL)hidePaid;                // hide_paid
+ (BOOL)simpleMode;              // simple_mode
+ (BOOL)regionSpoofEnabled;      // region_spoof_enabled (default YES)
+ (NSString *)selectedRegionISO; // selected_region_iso (default KZ)
+ (BOOL)alwaysShowProgressBar;   // always_show_progress_bar
+ (BOOL)downloadButton;          // download_button (default YES)
+ (BOOL)removeWatermark;         // remove_watermark (default YES)
+ (BOOL)skipQualityPicker;       // skip_quality_picker (default YES)
+ (BOOL)photoSave;               // tiktokyou_photo_save
+ (BOOL)antiBurnout;             // anti_burnout
+ (BOOL)antiBurnoutShowOnMain;   // anti_burnout_show_on_main
+ (BOOL)antiBurnoutEnableOnStart;// anti_burnout_enable_on_start
+ (NSInteger)feedOverlayTransparency; // feed_overlay_transparency 0-100
+ (NSArray<NSString *> *)filterWords; // hide_by_words_filter
+ (long long)filterMinLikes;     // hide_by_likes
+ (long long)filterMinViews;     // hide_by_views
+ (long long)filterMinDate;      // hide_by_publish_date (unix ts, 0=off)
+ (BOOL)uiHideEnabled;           // ui_hide_enabled
+ (NSDictionary *)uiHideRules;   // ui_hide_rules
+ (BOOL)customColorsEnabled;     // custom_colors_enabled
+ (UIColor *)accentColor;        // accent_color (int)
+ (BOOL)rainbowModeEnabled;      // rainbow_mode_enabled
+ (NSString *)selectedFont;      // selected_font
+ (BOOL)cleanShareLinks;         // clean_share_links
+ (BOOL)alwaysOpenSafari;        // openInBrowser
+ (BOOL)startupConsentAccepted;  // startup_consent_accepted
+ (BOOL)launchedFirstTime;       // launched_first_time

// helpers
+ (void)saveMedia:(id)item fileExtension:(id)fileExtension;
+ (void)showSaveVC:(id)item;
+ (void)cleanCache;
+ (BOOL)isEmpty:(NSURL *)url;
@end

// Hook logging: writes to Documents/tiktokyou_hooklog.txt, shown in menu
@interface HookLog: NSObject
+ (void)log:(NSString *)fmt, ...;
+ (NSString *)contents;
+ (void)clear;
@end

// Region info helper (name/ISO/mcc/mnc per TikTok You quick list)
@interface RegionInfo: NSObject
+ (NSArray<NSDictionary *> *)allRegions;  // full picker list (RU names)
+ (NSDictionary *)regionForISO:(NSString *)iso;
+ (NSDictionary *)currentRegion;  // legacy dict {area,name,code,mcc,mnc} for region hooks
@end
