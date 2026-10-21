//
//  YouSettingsViewController.m — мод-меню «TikTok You» (структура 1:1 к Android-моду)
//  Тёмная тема #1E1E1E, текст #F5F5F5, акцент #FE2B54
//

#import <UIKit/UIKit.h>
#import "BHIManager.h"
#import "YouSettingsViewController.h"
#import "YouRegionPicker.h"
#import "YouFilterWords.h"
#import "YouHookLogVC.h"

#define YOU_BG      [UIColor colorWithRed:0x1E/255.0 green:0x1E/255.0 blue:0x1E/255.0 alpha:1]
#define YOU_CARD    [UIColor colorWithRed:0x2A/255.0 green:0x2A/255.0 blue:0x2A/255.0 alpha:1]
#define YOU_TEXT    [UIColor colorWithRed:0xF5/255.0 green:0xF5/255.0 blue:0xF5/255.0 alpha:1]
#define YOU_SUBTEXT [UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1]
#define YOU_ACCENT  [UIColor colorWithRed:0xFE/255.0 green:0x2B/255.0 blue:0x54/255.0 alpha:1]

static NSString *modVersion(void) {
    return @"TikTok You 1.0 (iOS)";
}

typedef NS_ENUM(NSInteger, YouRowKind) {
    YouRowSwitch,
    YouRowNavigation,
    YouRowButton,
    YouRowSlider,
    YouRowInfo,
};

@interface YouRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, copy) NSString *key;      // NSUserDefaults key
@property (nonatomic, assign) YouRowKind kind;
@property (nonatomic, copy) void (^action)(void);
@end
@implementation YouRow
@end

@interface YouSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSArray<YouRow *> *rows;
@end
@implementation YouSection
@end

@interface YouSettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSArray<YouSection *> *sections;
@end

@implementation YouSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = YOU_BG;
    self.title = @"Настройки мода";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithImage:[UIImage systemImageNamed:@"arrow.counterclockwise"]
        style:UIBarButtonItemStylePlain
        target:self action:@selector(resetTapped)];

    UILabel *header = [[UILabel alloc] init];
    header.text = modVersion();
    header.textColor = YOU_SUBTEXT;
    header.font = [UIFont systemFontOfSize:13];
    header.textAlignment = NSTextAlignmentCenter;
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [header.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];

    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.table.translatesAutoresizingMaskIntoConstraints = NO;
    self.table.backgroundColor = UIColor.clearColor;
    self.table.separatorColor = [UIColor colorWithWhite:1 alpha:0.08];
    self.table.dataSource = self;
    self.table.delegate = self;
    [self.view addSubview:self.table];
    [NSLayoutConstraint activateConstraints:@[
        [self.table.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:8],
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    [self buildSections];
}

- (void)buildSections {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];

    // --- Воспроизведение ---
    YouSection *playback = [YouSection new];
    playback.title = @"Воспроизведение";
    playback.rows = @[ [self rowWithTitle:@"Перемотка везде" detail:@"Прогресс-бар в каждом видео" key:@"always_show_progress_bar"] ];

    // --- Скрытие ---
    YouSection *hiding = [YouSection new];
    hiding.title = @"Скрытие";
    hiding.rows = @[
        [self rowWithTitle:@"Убрать рекламу" detail:nil key:@"hide_ads"],
        [self rowWithTitle:@"Убрать трансляции" detail:nil key:@"hide_lives"],
        [self rowWithTitle:@"Убрать фотографии" detail:@"Слайдшоу из фото" key:@"hide_photos"],
        [self rowWithTitle:@"Убрать истории" detail:@"Stories" key:@"hide_stories"],
        [self rowWithTitle:@"Убрать мини-сериалы" detail:nil key:@"hide_series"],
        [self rowWithTitle:@"Убрать платный контент" detail:nil key:@"hide_paid"],
    ];

    // --- Регион ---
    YouRow *regionSpoof = [self rowWithTitle:@"Подмена региона" detail:@"Рекомендации по выбранной стране" key:@"region_spoof_enabled"];
    YouRow *regionPick = [YouRow new];
    regionPick.title = @"Выбрать регион";
    regionPick.kind = YouRowNavigation;
    regionPick.detail = [RegionInfo regionForISO:[BHIManager selectedRegionISO]][@"name"];
    regionPick.action = ^{
        YouRegionPicker *picker = [[YouRegionPicker alloc] init];
        picker.onSelect = ^(NSDictionary *region) {
            [d setObject:region[@"code"] forKey:@"selected_region_iso"];
            [d setObject:@{@"area": [NSString stringWithFormat:@"%@ (%@)", region[@"name"], region[@"code"]],
                          @"name": region[@"name"], @"code": region[@"code"],
                          @"mcc": region[@"mcc"], @"mnc": region[@"mnc"]}
                 forKey:@"region"];
        };
        [self.navigationController pushViewController:picker animated:YES];
    };
    YouSection *region = [YouSection new];
    region.title = @"Регион";
    region.rows = @[regionSpoof, regionPick];

    // --- Лента ---
    YouSection *feed = [YouSection new];
    feed.title = @"Лента";
    feed.rows = @[
        [self rowWithTitle:@"Кнопка скачивания" detail:@"Кнопка Download на видео" key:@"download_button"],
        [self rowWithTitle:@"Скачивать без водяного знака" detail:nil key:@"remove_watermark"],
        [self rowWithTitle:@"Скачивание фото" detail:@"Сохранять фото без watermark" key:@"tiktokyou_photo_save"],
        [self rowWithTitle:@"Пропускать выбор качества" detail:@"Сразу лучшее качество" key:@"skip_quality_picker"],
        [self rowWithTitle:@"Минимализм" detail:@"Простой режим ленты" key:@"simple_mode"],
        [self rowWithTitle:@"Антивыгорание" detail:@"Затемнение интерфейса" key:@"anti_burnout"],
        [self rowWithTitle:@"Антивыгорание на главной" detail:nil key:@"anti_burnout_show_on_main"],
        [self rowWithTitle:@"Включать сразу" detail:@"При запуске приложения" key:@"anti_burnout_enable_on_start"],
    ];

    // --- Фильтры контента ---
    YouRow *wordsRow = [YouRow new];
    wordsRow.title = @"Слова и теги";
    wordsRow.detail = @"Скрывать видео со словами";
    wordsRow.kind = YouRowNavigation;
    wordsRow.action = ^{ [self.navigationController pushViewController:[[YouFilterWords alloc] init] animated:YES]; };

    YouRow *likesRow = [YouRow new];
    likesRow.title = @"Лайки"; likesRow.kind = YouRowButton;
    likesRow.detail = [self formatFilterValue:[BHIManager filterMinLikes]];
    {
    __weak YouRow *wRow = likesRow;
    likesRow.action = ^{ [self promptNumber:@"Минимум лайков" key:@"hide_by_likes" hint:@"Скрывает видео с меньшим числом лайков" refresh:^{ wRow.detail = [self formatFilterValue:[BHIManager filterMinLikes]]; [self.table reloadData]; }]; };
}

    YouRow *viewsRow = [YouRow new];
    viewsRow.title = @"Просмотры"; viewsRow.kind = YouRowButton;
    viewsRow.detail = [self formatFilterValue:[BHIManager filterMinViews]];
    {
    __weak YouRow *wRow = viewsRow;
    viewsRow.action = ^{ [self promptNumber:@"Минимум просмотров" key:@"hide_by_views" hint:@"Скрывает видео с меньшим числом просмотров" refresh:^{ wRow.detail = [self formatFilterValue:[BHIManager filterMinViews]]; [self.table reloadData]; }]; };
}

    YouRow *dateRow = [YouRow new];
    dateRow.title = @"Дата публикации"; dateRow.kind = YouRowButton;
    dateRow.detail = [BHIManager filterMinDate] > 0 ? [self formatDateFilter:[BHIManager filterMinDate]] : @"Выкл";
    {
    __weak YouRow *wRow = dateRow;
    dateRow.action = ^{ [self promptDateWithHint:@"Скрывает более старые видео" key:@"hide_by_publish_date" refresh:^{ wRow.detail = [BHIManager filterMinDate] > 0 ? [self formatDateFilter:[BHIManager filterMinDate]] : @"Выкл"; [self.table reloadData]; }]; };
}

    YouSection *filters = [YouSection new];
    filters.title = @"Фильтры контента";
    filters.rows = @[wordsRow, likesRow, viewsRow, dateRow];

    // --- Внешний вид ---
    YouRow *accentRow = [YouRow new];
    accentRow.title = @"Акцентный цвет"; accentRow.kind = YouRowButton;
    accentRow.detail = [BHIManager customColorsEnabled] ? @"Включён" : @"Выключен";
    accentRow.action = ^{ [self showColorPicker]; };

    YouSection *appearance = [YouSection new];
    appearance.title = @"Внешний вид";
    appearance.rows = @[
        accentRow,
        [self rowWithTitle:@"Радужный режим" detail:@"Переливающийся акцент" key:@"rainbow_mode_enabled"],
        [self rowWithTitle:@"Скрытие элементов" detail:@"Убрать кнопки ленты" key:@"ui_hide_enabled"],
    ];

    // --- Остальное ---
    YouSection *misc = [YouSection new];
    misc.title = @"Остальное";
    misc.rows = @[
        [self rowWithTitle:@"Чистые ссылки" detail:@"Убирать трекинг из ссылок" key:@"clean_share_links"],
        [self rowWithTitle:@"Ссылки в Safari" detail:@"Открывать вне приложения" key:@"openInBrowser"],
    ];

    // --- О приложении ---
    YouRow *uidRow = [YouRow new];
    uidRow.title = @"Копировать UID"; uidRow.kind = YouRowButton;
    uidRow.detail = @"Идентификатор аккаунта";
    uidRow.action = ^{ [self copyUID]; };

    YouRow *logRow = [YouRow new];
    logRow.title = @"Лог хуков"; logRow.kind = YouRowNavigation;
    logRow.detail = @"Ошибки и статус фич";
    logRow.action = ^{ [self.navigationController pushViewController:[[YouHookLogVC alloc] init] animated:YES]; };

    YouRow *updatesRow = [YouRow new];
    updatesRow.title = @"Проверить обновления"; updatesRow.kind = YouRowButton;
    updatesRow.detail = @"GitHub Releases";
    updatesRow.action = ^{ [self openURL:@"https://github.com/ItzChelove4ik/tiktokyou-ios/releases"]; };

    YouRow *tgRow = [YouRow new];
    tgRow.title = @"Сообщество"; tgRow.kind = YouRowButton;
    tgRow.detail = @"Telegram";
    tgRow.action = ^{ [self openURL:@"https://t.me/tikyoutok"]; };

    YouRow *faqRow = [YouRow new];
    faqRow.title = @"Частые вопросы"; faqRow.kind = YouRowButton;
    faqRow.detail = @"FAQ";
    faqRow.action = ^{ [self openURL:@"https://tiktokyou.ru/knowledge.html"]; };

    YouSection *about = [YouSection new];
    about.title = @"О приложении";
    about.rows = @[uidRow, logRow, updatesRow, tgRow, faqRow];

    self.sections = @[playback, hiding, region, feed, filters, appearance, misc, about];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.sections[section].rows.count; }

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section].title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *l = [[UILabel alloc] init];
    l.text = [self.sections[section].title uppercaseString];
    l.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    l.textColor = YOU_ACCENT;
    l.frame = CGRectMake(16, 12, 300, 20);
    return l;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 36; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YouRow *row = self.sections[indexPath.section].rows[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"you"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"you"];
        cell.backgroundColor = YOU_CARD;
        cell.textLabel.textColor = YOU_TEXT;
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.detailTextLabel.textColor = YOU_SUBTEXT;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = row.title;
    cell.detailTextLabel.text = row.detail;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (row.kind) {
        case YouRowSwitch: {
            UISwitch *sw = [[UISwitch alloc] init];
            sw.onTintColor = YOU_ACCENT;
            sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:row.key];
            [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            sw.tag = 1000 + indexPath.section * 100 + indexPath.row;
            cell.accessoryView = sw;
            break;
        }
        case YouRowNavigation:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    YouRow *row = self.sections[indexPath.section].rows[indexPath.row];
    if (row.kind != YouRowSwitch && row.action) {
        row.action();
    }
}

- (void)switchChanged:(UISwitch *)sender {
    NSIndexPath *ip = [NSIndexPath indexPathForRow:sender.tag % 100 inSection:(sender.tag - 100) / 100];
    if (ip.section < (NSInteger)self.sections.count && ip.row < (NSInteger)self.sections[ip.section].rows.count) {
        YouRow *row = self.sections[ip.section].rows[ip.row];
        [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:row.key];
        // live feedback
        if ([row.key isEqualToString:@"region_spoof_enabled"]) {
            [HookLog log:@"region spoof %@ (iso=%@)", sender.on ? @"ON" : @"OFF", [BHIManager selectedRegionISO]];
        }
    }
}

#pragma mark - actions

- (void)copyUID {
    NSString *uid = nil;
    Class accountServiceClass = NSClassFromString(@"AWEAccountService");
    if (accountServiceClass) {
        id sharedService = [accountServiceClass respondsToSelector:@selector(sharedService)] ? [accountServiceClass performSelector:@selector(sharedService)] : nil;
        id userModel = sharedService ? [sharedService valueForKey:@"currentUserModel"] : nil;
        uid = userModel ? [userModel valueForKey:@"uid"] : nil;
    }
    if (!uid.length) {
        uid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    UIPasteboard.generalPasteboard.string = uid;
    [self showToast:[NSString stringWithFormat:@"UID скопирован: %@", uid]];
}

- (void)openURL:(NSString *)url {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
        options:@{} completionHandler:nil];
}

- (void)showColorPicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Акцентный цвет"
        message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSDictionary *colors = @{@"Розовый (TikTok You)": @0xFE2B54, @"Синий": @0x40C4E0, @"Зелёный": @0x00E676, @"Оранжевый": @0xFF9800, @"Фиолетовый": @0xB388FF, @"Выключить": [NSNull null]};
    for (NSString *name in colors) {
        [alert addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            id v = colors[name];
            NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
            if ([v isEqual:[NSNull null]]) {
                [d setBool:NO forKey:@"custom_colors_enabled"];
            } else {
                [d setBool:YES forKey:@"custom_colors_enabled"];
                [d setInteger:[v integerValue] forKey:@"accent_color"];
            }
            [self.table reloadData];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptNumber:(NSString *)title key:(NSString *)key hint:(NSString *)hint refresh:(void(^)(void))refresh {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:hint preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.text = [NSString stringWithFormat:@"%ld", (long)[[NSUserDefaults standardUserDefaults] integerForKey:key]];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"ОК" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        long long v = [alert.textFields.firstObject.text longLongValue];
        [[NSUserDefaults standardUserDefaults] setInteger:v forKey:key];
        if (refresh) refresh();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Сброс" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:key];
        if (refresh) refresh();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptDateWithHint:(NSString *)hint key:(NSString *)key refresh:(void(^)(void))refresh {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Дата публикации" message:hint preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"ГГГГ-ММ-ДД";
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd"];
        long long cur = [[NSUserDefaults standardUserDefaults] integerForKey:key];
        if (cur > 0) tf.text = [df stringFromDate:[NSDate dateWithTimeIntervalSince1970:cur]];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"ОК" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd"];
        NSDate *date = [df dateFromString:alert.textFields.firstObject.text];
        [[NSUserDefaults standardUserDefaults] setInteger:(long long)[date timeIntervalSince1970] forKey:key];
        if (refresh) refresh();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Сброс" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:key];
        if (refresh) refresh();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)formatFilterValue:(long long)v {
    return v > 0 ? [NSString stringWithFormat:@"%lld", v] : @"Выкл";
}

- (NSString *)formatDateFilter:(long long)ts {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd.MM.yyyy"];
    return [df stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
}

- (void)resetTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Сбросить настройки?"
        message:@"Все настройки мода вернутся к значениям по умолчанию, после чего приложение перезапустится."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Сбросить" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain ?: @""];
        exit(0);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)text {
    UILabel *toast = [[UILabel alloc] init];
    toast.text = text;
    toast.textColor = YOU_TEXT;
    toast.backgroundColor = [YOU_CARD colorWithAlphaComponent:0.95];
    toast.layer.cornerRadius = 10;
    toast.clipsToBounds = YES;
    toast.numberOfLines = 2;
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:14];
    toast.frame = CGRectMake(20, self.view.bounds.size.height - 110, self.view.bounds.size.width - 40, 44);
    toast.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:toast];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{ toast.alpha = 0; } completion:^(BOOL f) { [toast removeFromSuperview]; }];
    });
}


- (YouRow *)rowWithTitle:(NSString *)title detail:(NSString *)detail key:(NSString *)key {
    YouRow *row = [YouRow new];
    row.title = title; row.detail = detail; row.key = key;
    row.kind = YouRowSwitch;
    return row;
}

@end
