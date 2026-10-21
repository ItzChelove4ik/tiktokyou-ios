//
//  YouRegionPicker.m — пикер регионов TikTok You (полный список, RU-названия)
//
#import <UIKit/UIKit.h>
#import "BHIManager.h"
#import "YouRegionPicker.h"

#define YOU_BG      [UIColor colorWithRed:0x1E/255.0 green:0x1E/255.0 blue:0x1E/255.0 alpha:1]
#define YOU_CARD    [UIColor colorWithRed:0x2A/255.0 green:0x2A/255.0 blue:0x2A/255.0 alpha:1]
#define YOU_TEXT    [UIColor colorWithRed:0xF5/255.0 green:0xF5/255.0 blue:0xF5/255.0 alpha:1]
#define YOU_SUBTEXT [UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1]
#define YOU_ACCENT  [UIColor colorWithRed:0xFE/255.0 green:0x2B/255.0 blue:0x54/255.0 alpha:1]

@interface YouRegionPicker : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, copy) void (^onSelect)(NSDictionary *region);
@end

@interface YouRegionPicker ()
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) UISearchBar *search;
@property (nonatomic, strong) NSArray<NSDictionary *> *all;
@property (nonatomic, strong) NSArray<NSDictionary *> *filtered;
@end

@implementation YouRegionPicker

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = YOU_BG;
    self.title = @"Выбрать регион";

    self.all = [RegionInfo allRegions];
    self.filtered = self.all;

    self.search = [[UISearchBar alloc] init];
    self.search.placeholder = @"Поиск региона";
    self.search.delegate = self;
    self.search.barStyle = UIBarStyleBlack;
    self.search.searchBarStyle = UISearchBarStyleMinimal;
    [self.search sizeToFit];

    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.table.translatesAutoresizingMaskIntoConstraints = NO;
    self.table.backgroundColor = UIColor.clearColor;
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.tableHeaderView = self.search;
    [self.view addSubview:self.table];
    [NSLayoutConstraint activateConstraints:@[
        [self.table.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!searchText.length) { self.filtered = self.all; }
    else {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR code CONTAINS[cd] %@", searchText, searchText];
        self.filtered = [self.all filteredArrayUsingPredicate:p];
    }
    [self.table reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filtered.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"region"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"region"];
        cell.backgroundColor = YOU_CARD;
        cell.textLabel.textColor = YOU_TEXT;
        cell.detailTextLabel.textColor = YOU_SUBTEXT;
    }
    NSDictionary *r = self.filtered[indexPath.row];
    cell.textLabel.text = r[@"name"];
    cell.detailTextLabel.text = r[@"code"];
    cell.accessoryType = [r[@"code"] isEqualToString:[BHIManager selectedRegionISO]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *r = self.filtered[indexPath.row];
    if (self.onSelect) self.onSelect(r);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
