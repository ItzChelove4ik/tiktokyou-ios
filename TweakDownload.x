// TweakDownload.x — скачивание (кнопка Download + обработчики) из базы BHTikTok
// Вставляется %group-ами; ключи обновлены под TikTok You.
#import "TikTokHeaders.h"
#import "BHIManager.h"

%group TikTokYouDownload
%hook AWEFeedViewTemplateCell
%property (nonatomic, strong) JGProgressHUD *hud;
%property(nonatomic, assign) BOOL elementsHidden;
%property (nonatomic, retain) NSString *fileextension;
%property (nonatomic, retain) UIProgressView *progressView;
- (void)configWithModel:(id)model {
    %orig;
    self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
}
- (void)configureWithModel:(id)model {
    %orig;
    self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
}
%new - (void)addDownloadButton {
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:998];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
    if (![self viewWithTag:998]) {
        [downloadButton setTintColor:[UIColor whiteColor]];
        [self addSubview:downloadButton];

        [NSLayoutConstraint activateConstraints:@[
            [downloadButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [downloadButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [downloadButton.widthAnchor constraintEqualToConstant:30],
            [downloadButton.heightAnchor constraintEqualToConstant:30],
        ]];
    }
}
%new - (void)downloadHDVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://tikwm.com/video/media/hdplay/%@.mp4", as]];
    self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)downloadVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)downloadPhotos:(TTKPhotoAlbumDetailCellController *)rootVC photoIndex:(unsigned long)index {
    AWEPlayPhotoAlbumViewController *photoAlbumController = [rootVC valueForKey:@"_photoAlbumController"];
            NSArray <AWEPhotoAlbumPhoto *> *photos = rootVC.model.photoAlbum.photos;
            AWEPhotoAlbumPhoto *currentPhoto = [photos objectAtIndex:index];

                NSURL *downloadableURL = [currentPhoto.originPhotoURL bestURLtoDownload];
                self.fileextension = [currentPhoto.originPhotoURL bestURLtoDownloadFormat];
                if (downloadableURL) {
                    BHDownload *dwManager = [[BHDownload alloc] init];
                    [dwManager downloadFileWithURL:downloadableURL];
                    [dwManager setDelegate:self];
                    self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                    self.hud.textLabel.text = @"Downloading";
                     [self.hud showInView:topMostController().view];
                }
            
    }

%new - (void)downloadPhotos:(TTKPhotoAlbumDetailCellController *)rootVC {
    NSString *video_description = rootVC.model.music_songName;
    AWEPlayPhotoAlbumViewController *photoAlbumController = [rootVC valueForKey:@"_photoAlbumController"];

            NSArray <AWEPhotoAlbumPhoto *> *photos = rootVC.model.photoAlbum.photos;
            NSMutableArray<NSURL *> *fileURLs = [NSMutableArray array];

            for (AWEPhotoAlbumPhoto *currentPhoto in photos) {
                NSURL *downloadableURL = [currentPhoto.originPhotoURL bestURLtoDownload];
                self.fileextension = [currentPhoto.originPhotoURL bestURLtoDownloadFormat];
                if (downloadableURL) {
                    [fileURLs addObject:downloadableURL];
                }
            }

            BHMultipleDownload *dwManager = [[BHMultipleDownload alloc] init];
            [dwManager setDelegate:self];
            [dwManager downloadFiles:fileURLs];
            self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            self.hud.textLabel.text = @"Downloading";
            [self.hud showInView:topMostController().view];

}
%new - (void)downloadMusic:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    self.fileextension = @"mp3";
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)copyMusic:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [((AWEMusicModel *)rootVC.model.music).playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"Could Not Copy Music." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)copyVideo:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)copyDecription:(AWEAwemeBaseViewController *)rootVC {
    NSString *video_description = rootVC.model.music_songName;
    if (video_description) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = video_description;
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void) downloadButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC isKindOfClass:%c(AWEFeedCellViewController)]) {

         UIAction *action1 = [UIAction actionWithTitle:@"Download Video"
                                            image:[UIImage systemImageNamed:@"film"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadVideo:rootVC];
    }];
        UIAction *action0 = [UIAction actionWithTitle:@"Download HD Video"
                                            image:[UIImage systemImageNamed:@"film"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadHDVideo:rootVC];
    }];
    UIAction *action2 = [UIAction actionWithTitle:@"Download Music"
                                            image:[UIImage systemImageNamed:@"music.note"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadMusic:rootVC];
    }];
    UIAction *action3 = [UIAction actionWithTitle:@"Copy Music link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyMusic:rootVC];
    }];
    UIAction *action4 = [UIAction actionWithTitle:@"Copy Video link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyVideo:rootVC];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"Copy Decription"
                                            image:[UIImage systemImageNamed:@"note.text"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyDecription:rootVC];
    }];
    UIMenu *downloadMenu = [UIMenu menuWithTitle:@"Downloads Menu"
                                        children:@[action1, action0,action2]];
    UIMenu *copyMenu = [UIMenu menuWithTitle:@"Copy Menu"
                                        children:@[action3, action4, action5]];
    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[downloadMenu, copyMenu]];
    [sender setMenu:mainMenu];
    sender.showsMenuAsPrimaryAction = YES;
    } else if ([self.viewController isKindOfClass:%c(TTKPhotoAlbumDetailCellController)]) {
        TTKPhotoAlbumDetailCellController *rootVC = self.viewController;
        AWEPlayPhotoAlbumViewController *photoAlbumController = [rootVC valueForKey:@"_photoAlbumController"];
        NSArray <AWEPhotoAlbumPhoto *> *photos = rootVC.model.photoAlbum.photos;
        unsigned long photosCount = [photos count];
        NSMutableArray <UIAction *> *photosActions = [NSMutableArray array];
            for (int i = 0; i < photosCount; i++) {
        NSString *title = [NSString stringWithFormat:@"Download Photo %d", i+1];
        UIAction *action = [UIAction actionWithTitle:title
                                               image:[UIImage systemImageNamed:@"photo.fill"]
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
                                                [self downloadPhotos:rootVC photoIndex:i];
        }];
        [photosActions addObject:action];

    }
    UIAction *allPhotosAction = [UIAction actionWithTitle:@"Download All Photos"
                                            image:[UIImage systemImageNamed:@"photo.fill"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadPhotos:rootVC];
    }];
    [photosActions addObject:allPhotosAction];
    UIAction *action2 = [UIAction actionWithTitle:@"Download Music"
                                            image:[UIImage systemImageNamed:@"music.note"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadMusic:rootVC];
    }];
    UIAction *action3 = [UIAction actionWithTitle:@"Copy Music link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyMusic:rootVC];
    }];
    UIAction *action4 = [UIAction actionWithTitle:@"Copy Video link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyVideo:rootVC];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"Copy Decription"
                                            image:[UIImage systemImageNamed:@"note.text"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyDecription:rootVC];
    }];
    UIMenu *PhotosMenu = [UIMenu menuWithTitle:@"Download Photos Menu"
                                        children:photosActions];
    UIMenu *downloadMenu = [UIMenu menuWithTitle:@"Downloads Menu"
                                        children:@[action2]];
    UIMenu *copyMenu = [UIMenu menuWithTitle:@"Copy Menu"
                                        children:@[action3, action4, action5]];
    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[PhotosMenu, downloadMenu, copyMenu]];
    [sender setMenu:mainMenu];
    sender.showsMenuAsPrimaryAction = YES;
    }else if ([self.viewController isKindOfClass:%c(TTKPhotoAlbumFeedCellController)]) {
        TTKPhotoAlbumFeedCellController *rootVC = self.viewController;
        AWEPlayPhotoAlbumViewController *photoAlbumController = [rootVC valueForKey:@"_photoAlbumController"];
        NSArray <AWEPhotoAlbumPhoto *> *photos = rootVC.model.photoAlbum.photos;
        unsigned long photosCount = [photos count];
        NSMutableArray <UIAction *> *photosActions = [NSMutableArray array];
            for (int i = 0; i < photosCount; i++) {
        NSString *title = [NSString stringWithFormat:@"Download Photo %d", i+1];
        UIAction *action = [UIAction actionWithTitle:title
                                               image:[UIImage systemImageNamed:@"photo.fill"]
                                          identifier:nil
                                             handler:^(__kindof UIAction * _Nonnull action) {
                                                [self downloadPhotos:rootVC photoIndex:i];
        }];
        [photosActions addObject:action];

    }
        UIAction *allPhotosAction = [UIAction actionWithTitle:@"Download Photos"
                                            image:[UIImage systemImageNamed:@"photo.fill"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadPhotos:rootVC];
    }];
    [photosActions addObject:allPhotosAction];
    UIAction *action2 = [UIAction actionWithTitle:@"Download Music"
                                            image:[UIImage systemImageNamed:@"music.note"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadMusic:rootVC];
    }];
    UIAction *action3 = [UIAction actionWithTitle:@"Copy Music link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyMusic:rootVC];
    }];
    UIAction *action4 = [UIAction actionWithTitle:@"Copy Video link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyVideo:rootVC];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"Copy Decription"
                                            image:[UIImage systemImageNamed:@"note.text"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyDecription:rootVC];
    }];
    UIMenu *PhotosMenu = [UIMenu menuWithTitle:@"Download Photos Menu"
                                        children:photosActions];
    UIMenu *downloadMenu = [UIMenu menuWithTitle:@"Downloads Menu"
                                        children:@[action2]];
    UIMenu *copyMenu = [UIMenu menuWithTitle:@"Copy Menu"
                                        children:@[action3, action4, action5]];
    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[PhotosMenu, downloadMenu, copyMenu]];
    [sender setMenu:mainMenu];
    sender.showsMenuAsPrimaryAction = YES;
    }
}
%new - (void)addHideElementButton {
    UIButton *hideElementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [hideElementButton setTag:999];
    [hideElementButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [hideElementButton addTarget:self action:@selector(hideElementButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    if (self.elementsHidden) {
        [hideElementButton setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
    } else {
        [hideElementButton setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
    }

    if (![self viewWithTag:999]) {
        [hideElementButton setTintColor:[UIColor whiteColor]];
        [self addSubview:hideElementButton];

        [NSLayoutConstraint activateConstraints:@[
            [hideElementButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:50],
            [hideElementButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [hideElementButton.widthAnchor constraintEqualToConstant:30],
            [hideElementButton.heightAnchor constraintEqualToConstant:30],
        ]];
    }
}
%new - (void)hideElementButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
        TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
        if (self.elementsHidden) {
            self.elementsHidden = false;
            [interactionController hideAllElements:false exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
        } else {
            self.elementsHidden = true;
            [interactionController hideAllElements:true exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
        }
    }
}

%new - (void)downloaderProgress:(float)progress {
    self.hud.detailTextLabel.text = [BHIManager getDownloadingPersent:progress];
}
%new - (void)downloaderDidFinishDownloadingAllFiles:(NSMutableArray<NSURL *> *)downloadedFilePaths {
    [self.hud dismiss];
    if ([BHIManager shareSheet]) {
        [BHIManager showSaveVC:downloadedFilePaths];
    }
    else {
        for (NSURL *url in downloadedFilePaths) {
            [BHIManager saveMedia:url fileExtension:self.fileextension];
        }
    }
}
%new - (void)downloaderDidFailureWithError:(NSError *)error {
    if (error) {
        [self.hud dismiss];
    }
}

%new - (void)downloadProgress:(float)progress {
    self.progressView.progress = progress;
    self.hud.detailTextLabel.text = [BHIManager getDownloadingPersent:progress];
    self.hud.tapOutsideBlock = ^(JGProgressHUD * _Nonnull HUD) {
        self.hud.textLabel.text = @"Backgrounding ✌️";
        [self.hud dismissAfterDelay:0.4];
    };
}
%new - (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName {
    NSString *DocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *newFilePath = [[NSURL fileURLWithPath:DocPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString, self.fileextension]];
    [manager moveItemAtURL:filePath toURL:newFilePath error:nil];
    [self.hud dismiss];
    NSArray *audioExtensions = @[@"mp3", @"aac", @"wav", @"m4a", @"ogg", @"flac", @"aiff", @"wma"];
    if ([BHIManager shareSheet] || [audioExtensions containsObject:self.fileextension]) {
        [BHIManager showSaveVC:@[newFilePath]];
    }
    else {
        [BHIManager saveMedia:newFilePath fileExtension:self.fileextension];
    }
}
%new - (void)downloadDidFailureWithError:(NSError *)error {
    if (error) {
        [self.hud dismiss];
    }
}
%end

%hook AWEAwemeDetailTableViewCell
%property (nonatomic, strong) JGProgressHUD *hud;
%property(nonatomic, assign) BOOL elementsHidden;
%property (nonatomic, retain) UIProgressView *progressView;
%property (nonatomic, retain) NSString *fileextension;
- (void)configWithModel:(id)model {
    %orig;
    self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
}
- (void)configureWithModel:(id)model {
    %orig;
    self.elementsHidden = false;
    if ([BHIManager downloadButton]){
        [self addDownloadButton];
    }
}
%new - (void)addDownloadButton {
    UIButton *downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [downloadButton setTag:998];
    [downloadButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [downloadButton addTarget:self action:@selector(downloadButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    [downloadButton setImage:[UIImage systemImageNamed:@"arrow.down"] forState:UIControlStateNormal];
    if (![self viewWithTag:998]) {
        [downloadButton setTintColor:[UIColor whiteColor]];
        [self addSubview:downloadButton];

        [NSLayoutConstraint activateConstraints:@[
            [downloadButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:90],
            [downloadButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [downloadButton.widthAnchor constraintEqualToConstant:30],
            [downloadButton.heightAnchor constraintEqualToConstant:30],
        ]];
    }
}
%new - (void)downloadHDVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://tikwm.com/video/media/hdplay/%@.mp4", as]];
    self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)downloadVideo:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
        self.fileextension = [rootVC.model.video.playURL bestURLtoDownloadFormat];
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)downloadMusic:(AWEAwemeBaseViewController *)rootVC {
    NSString *as = rootVC.model.itemID;
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
        self.fileextension = @"mp3";
    if (downloadableURL) {
        BHDownload *dwManager = [[BHDownload alloc] init];
        [dwManager downloadFileWithURL:downloadableURL];
        [dwManager setDelegate:self];
        self.hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        self.hud.textLabel.text = @"Downloading";
        [self.hud showInView:topMostController().view];
    }
}
%new - (void)copyMusic:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [((AWEMusicModel *)rootVC.model.music).playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)copyVideo:(AWEAwemeBaseViewController *)rootVC {
    NSURL *downloadableURL = [rootVC.model.video.playURL bestURLtoDownload];
    if (downloadableURL) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [downloadableURL absoluteString];
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void)copyDecription:(AWEAwemeBaseViewController *)rootVC {
    NSString *video_description = rootVC.model.music_songName;
    if (video_description) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = video_description;
    } else {
        [%c(AWEUIAlertView) showAlertWithTitle:@"BHTikTok, Hi" description:@"The video dosen't have music to download." image:nil actionButtonTitle:@"OK" cancelButtonTitle:nil actionBlock:nil cancelBlock:nil];
    }
}
%new - (void) downloadButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {

     UIAction *action1 = [UIAction actionWithTitle:@"Download Video"
                                            image:[UIImage systemImageNamed:@"film"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadVideo:rootVC];
    }];
    UIAction *action0 = [UIAction actionWithTitle:@"Download HD Video"
                                            image:[UIImage systemImageNamed:@"film"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadHDVideo:rootVC];
    }];
    UIAction *action2 = [UIAction actionWithTitle:@"Download Music"
                                            image:[UIImage systemImageNamed:@"music.note"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self downloadMusic:rootVC];
    }];
    UIAction *action3 = [UIAction actionWithTitle:@"Copy Music link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyMusic:rootVC];
    }];
    UIAction *action4 = [UIAction actionWithTitle:@"Copy Video link"
                                            image:[UIImage systemImageNamed:@"link"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyVideo:rootVC];
    }];
    UIAction *action5 = [UIAction actionWithTitle:@"Copy Decription"
                                            image:[UIImage systemImageNamed:@"note.text"]
                                       identifier:nil
                                          handler:^(__kindof UIAction * _Nonnull action) {
                                            [self copyDecription:rootVC];
    }];
    UIMenu *downloadMenu = [UIMenu menuWithTitle:@"Downloads Menu"
                                        children:@[action1, action0,action2]];
    UIMenu *copyMenu = [UIMenu menuWithTitle:@"Copy Menu"
                                        children:@[action3, action4, action5]];
    UIMenu *mainMenu = [UIMenu menuWithTitle:@"" children:@[downloadMenu, copyMenu]];
    [sender setMenu:mainMenu];
    sender.showsMenuAsPrimaryAction = YES;
    }
}
%new - (void)addHideElementButton {
    UIButton *hideElementButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [hideElementButton setTag:999];
    [hideElementButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [hideElementButton addTarget:self action:@selector(hideElementButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
    if (self.elementsHidden) {
        [hideElementButton setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
    } else {
        [hideElementButton setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
    }

    if (![self viewWithTag:999]) {
        [hideElementButton setTintColor:[UIColor whiteColor]];
        [self addSubview:hideElementButton];

        [NSLayoutConstraint activateConstraints:@[
            [hideElementButton.topAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:50],
            [hideElementButton.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor constant:-10],
            [hideElementButton.widthAnchor constraintEqualToConstant:30],
            [hideElementButton.heightAnchor constraintEqualToConstant:30],
        ]];
    }
}
%new - (void)hideElementButtonHandler:(UIButton *)sender {
    AWEAwemeBaseViewController *rootVC = self.viewController;
    if ([rootVC.interactionController isKindOfClass:%c(TTKFeedInteractionLegacyMainContainerElement)]) {
        TTKFeedInteractionLegacyMainContainerElement *interactionController = rootVC.interactionController;
        if (self.elementsHidden) {
            self.elementsHidden = false;
            [interactionController hideAllElements:false exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye.slash"] forState:UIControlStateNormal];
        } else {
            self.elementsHidden = true;
            [interactionController hideAllElements:true exceptArray:nil];
            [sender setImage:[UIImage systemImageNamed:@"eye"] forState:UIControlStateNormal];
        }
    }
}

%new - (void)downloadProgress:(float)progress {
        self.hud.tapOutsideBlock = ^(JGProgressHUD * _Nonnull HUD) {
        self.hud.textLabel.text = @"Backgrounding ✌️";
        [self.hud dismissAfterDelay:0.4];
    };
    self.progressView.progress = progress;
    self.hud.detailTextLabel.text = [BHIManager getDownloadingPersent:progress];
}
%new - (void)downloadDidFinish:(NSURL *)filePath Filename:(NSString *)fileName {
    NSString *DocPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *newFilePath = [[NSURL fileURLWithPath:DocPath] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString, self.fileextension]];
    [manager moveItemAtURL:filePath toURL:newFilePath error:nil];
    [self.hud dismiss];
    NSArray *audioExtensions = @[@"mp3", @"aac", @"wav", @"m4a", @"ogg", @"flac", @"aiff", @"wma"];
    if ([BHIManager shareSheet] || [audioExtensions containsObject:self.fileextension]) {
        [BHIManager showSaveVC:@[newFilePath]];
    }
    else {
        [BHIManager saveMedia:newFilePath fileExtension:self.fileextension];
    }
}
%new - (void)downloadDidFailureWithError:(NSError *)error {
    if (error) {
        [self.hud dismiss];
    }
}
%end

%hook AWEURLModel
%new - (NSString *)bestURLtoDownloadFormat {
    NSURL *bestURLFormat;
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"]) {
            bestURLFormat = @"mp4";
        } else if ([url containsString:@".jpeg"]) {
            bestURLFormat = @"jpeg";
        } else if ([url containsString:@".png"]) {
            bestURLFormat = @"png";
        } else if ([url containsString:@".mp3"]) {
            bestURLFormat = @"mp3";
        } else if ([url containsString:@".m4a"]) {
            bestURLFormat = @"m4a";
        }
    }
    if (bestURLFormat == nil) {
        bestURLFormat = @"m4a";
    }

    return bestURLFormat;
}
%new - (NSURL *)bestURLtoDownload {
    NSURL *bestURL;
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"] || [url containsString:@".jpeg"] || [url containsString:@".mp3"]) {
            bestURL = [NSURL URLWithString:url];
        }
    }

    if (bestURL == nil) {
        bestURL = [NSURL URLWithString:[self.originURLList firstObject]];
    }

    return bestURL;
}
%end
%end // group TikTokYouDownload
