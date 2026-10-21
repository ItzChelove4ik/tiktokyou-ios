//
//  YouFilterWords.m — редактор слов/тегов фильтра контента TikTok You
//
#import <UIKit/UIKit.h>
#import "BHIManager.h"

#define YOU_BG      [UIColor colorWithRed:0x1E/255.0 green:0x1E/255.0 blue:0x1E/255.0 alpha:1]
#define YOU_CARD    [UIColor colorWithRed:0x2A/255.0 green:0x2A/255.0 blue:0x2A/255.0 alpha:1]
#define YOU_TEXT    [UIColor colorWithRed:0xF5/255.0 green:0xF5/255.0 blue:0xF5/255.0 alpha:1]
#define YOU_SUBTEXT [UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1]
#define YOU_ACCENT  [UIColor colorWithRed:0xFE/255.0 green:0x2B/255.0 blue:0x54/255.0 alpha:1]

@interface YouFilterWords : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@interface YouFilterWords ()
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSMutableArray<NSString *> *words;
@end

@implementation YouFilterWords

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = YOU_BG;
    self.title = @"Слова и теги";

    self.words = [[[NSUserDefaults standardUserDefaults] stringArrayForKey:@"hide_by_words_filter"] ?: @[] mutableCopy];

    self.table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.table.translatesAutoresizingMaskIntoConstraints = NO;
    self.table.backgroundColor = UIColor.clearColor;
    self.table.dataSource = self;
    self.table.delegate = self;
    [self.view addSubview:self.table];
    [NSLayoutConstraint activateConstraints:@[
        [self.table.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.table.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.table.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.table.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithImage:[UIImage systemImageNamed:@"plus"]
        style:UIBarButtonItemStylePlain
        target:self action:@selector(addTapped)];
}

- (void)save {
    [[NSUserDefaults standardUserDefaults] setObject:[self.words copy] forKey:@"hide_by_words_filter"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.words.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"word"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"word"];
        cell.backgroundColor = YOU_CARD;
        cell.textLabel.textColor = YOU_TEXT;
    }
    cell.textLabel.text = self.words[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.words removeObjectAtIndex:indexPath.row];
        [self save];
        [self.table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)addTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Слово или тег"
        message:@"Скрывает видео с этим словом в описании или хэштегах"
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"Слово или тег"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Добавить" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *w = alert.textFields.firstObject.text.trimmingCharactersInSet:[NSCharacterSet whitespaceSet]];
        if (w.length) {
            [self.words addObject:w];
            [self save];
            [self.table reloadData];
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
