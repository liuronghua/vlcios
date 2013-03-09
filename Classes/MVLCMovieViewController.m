    //
//  MVLCMovieViewController.m
//  MobileVLC
//
//  Created by Romain Goyet on 06/07/10.
//  Copyright 2010 Applidium. All rights reserved.
//

#import <MediaLibraryKit/MLFile.h>
#import "MLFile+HD.h"

#import "MVLCMovieViewController.h"

@interface ExternalDisplayController : UIViewController
@end

@implementation ExternalDisplayController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return ~UIInterfaceOrientationMaskAll;
}

@end


@interface MVLCMovieViewController ()

@property (nonatomic, retain) UIWindow *externalWindow;

@end

static NSString * MVLCMovieViewControllerHUDFadeInAnimation = @"MVLCMovieViewControllerHUDFadeInAnimation";
static NSString * MVLCMovieViewControllerHUDFadeOutAnimation = @"MVLCMovieViewControllerHUDFadeOutAnimation";

@implementation MVLCMovieViewController
@synthesize movieView=_movieView, file=_file, url=_url, positionSlider=_positionSlider, playOrPauseButton=_playOrPauseButton, volumeSlider=_volumeSlider, HUDView=_HUDView, topView=_topView, remainingTimeLabel=_remainingTimeLabel, trackSelectorButton=_trackSelectorButton, doneBarButton=_doneBarButton;
@synthesize externalWindow = _externalWindow, playingExternallyView = _playingExternallyView;
@synthesize titleTvLabel = _titleTvLabel, descriptionTvLabel = _descriptionTvLabel;


- (id)init {
    self = [super initWithNibName:@"MVLCMovieView" bundle:nil];

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _mediaPlayer = [[VLCMediaPlayer alloc] init];
    [_mediaPlayer setDelegate:self];
    [_mediaPlayer setDrawable:self.movieView];
    UITapGestureRecognizer * tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleHUDVisibility:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.numberOfTouchesRequired = 1; 
    [self.movieView addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
    self.doneBarButton.title = NSLocalizedString(@"Done", @"playback tab bar");

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(appWillResign:) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidConnect:)
                   name:UIScreenDidConnectNotification object:nil];
    [center addObserver:self selector:@selector(handleExternalScreenDidDisconnect:)
                   name:UIScreenDidDisconnectNotification object:nil];

    _hudVisibility = YES;

    if ([self hasExternalDisplay]) {
        [self showOnExternalDisplay];
    }
    self.titleTvLabel.text = NSLocalizedString(@"TV Connected", @"TV Connected title");
    self.descriptionTvLabel.text = NSLocalizedString(@"The video is playing on TV", @"TV Connected description");

//    [self setHudVisibility:NO]; // This triggers a bug in the transition animation on the iPhone
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _wasPushedAnimated = animated;
    if (_navigationController != self.navigationController) {
        [_navigationController release];
        _navigationController = [self.navigationController retain]; // Working around an UIKit bug - if we're poped non-animated, self.navigationController will be nil in viewWillDisappear
    }
    [_navigationController setNavigationBarHidden:YES animated:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self addObserver:self forKeyPath:@"file" options:0 context:nil];
    if (self.file) {
        [_mediaPlayer setMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:self.file.url]]];
    } else if (self.url) {
        [_mediaPlayer setMedia:[VLCMedia mediaWithURL:self.url]];
    }
    if (self.file && self.file.isTooHugeForDevice) {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"file too big alert")
                                                             message:[NSLocalizedString(@"Your __MVLC_DEVICE__ is probably too slow to play this movie correctly.", @"file too big alert") stringByReplacingOccurrencesOfString:@"__MVLC_DEVICE__" withString:[UIDevice currentDevice].model]
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"file too big alert")
                                                   otherButtonTitles:NSLocalizedString(@"Try anyway", @"file too big alert"), nil];
        [alertView show];
        [alertView release];
    } else {
        [_mediaPlayer play];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    if (self.file && self.file.lastPosition && [self.file.lastPosition floatValue] < 0.99) {
        [_mediaPlayer setPosition:[self.file.lastPosition floatValue]];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [_mediaPlayer pause];
    [self removeObserver:self forKeyPath:@"file"];

    // Make sure we unset this
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [_navigationController setNavigationBarHidden:NO animated:animated];
    [_navigationController release];
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.file) {
        self.file.lastPosition = [NSNumber numberWithFloat:[_mediaPlayer position]];
    }
    [_mediaPlayer stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_topView release];
    [_HUDView release];
    [_playOrPauseButton release];
    [_positionSlider release];
    [_movieView release];
    [_mediaPlayer release];
    [_url release];
    [_file release];
    [_externalWindow release];

    [_playingExternallyView release];
    [_titleTvLabel release];
    [_descriptionTvLabel release];

    [super dealloc];
}

/* deprecated in iOS 6 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES; // We support all 4 orientations
}

/* introduced in iOS 6 */
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

/* introduced in iOS 6 */
- (BOOL)shouldAutorotate {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration {
    // Let's work around the "rotate + statusbar = weird re-layout"
    if ([UIApplication sharedApplication].statusBarHidden) {
        // If the status bar isn't here, let's "save the spot"
        self.topView.frame = CGRectMake(0.0f, 20.0f, self.topView.frame.size.width, self.topView.frame.size.height);
    } else {
        self.topView.frame = CGRectMake(0.0f, 0.0f, self.topView.frame.size.width, self.topView.frame.size.height);
    }
}

- (void)appWillResign:(NSNotification *)aNotification
{
    if (self.file) {
        self.file.lastPosition = [NSNumber numberWithFloat:[_mediaPlayer position]];
    }
}

#pragma mark -
#pragma mark Key-Value Observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self && [keyPath isEqualToString:@"file"]) {
        [_mediaPlayer setMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:self.file.url]]];
    }
}

#pragma mark -
#pragma mark Actions
- (IBAction)togglePlayOrPause:(id)sender {
    if ([_mediaPlayer isPlaying]) {
        [_mediaPlayer pause];
    } else {
        [_mediaPlayer play];
    }
}

- (IBAction)position:(id)sender {
    [_mediaPlayer setPosition:self.positionSlider.value];
}

- (IBAction)volume:(id)sender {
    NSLog(@"_mediaPlayer.audio = %@", _mediaPlayer.audio);
    NSLog(@"self.volumeSlider = %@", self.volumeSlider);
    _mediaPlayer.audio.volume =  self.volumeSlider.value * 200.0f; // FIXME: This is equal to VOLUME_MAX, as defined in VLCAudio.m ...
}

- (IBAction)goForward:(id)sender {
    [_mediaPlayer mediumJumpForward];
}

- (IBAction)goBackward:(id)sender {
    [_mediaPlayer mediumJumpBackward];
}

@synthesize hudVisibility=_hudVisibility;

- (void)setHudVisibility:(BOOL)targetvisibility {
    if (targetvisibility) {
        if (targetvisibility != _hudVisibility) {
            [UIView beginAnimations:MVLCMovieViewControllerHUDFadeInAnimation context:NULL];
        }
        self.HUDView.alpha = 1.0f;
        self.topView.alpha = 1.0f;
    } else {
        if (targetvisibility != _hudVisibility) {
            [UIView beginAnimations:MVLCMovieViewControllerHUDFadeOutAnimation context:NULL];
        }
        self.HUDView.alpha = 0.0f;
        self.topView.alpha = 0.0f;
    }
    [[UIApplication sharedApplication] setStatusBarHidden:!targetvisibility withAnimation:UIStatusBarAnimationFade];
    _hudVisibility = targetvisibility;
    [UIView setAnimationDelegate:self];
    [UIView commitAnimations];
    if ([[self movieView] respondsToSelector:@selector(updateConstraints)])
        [[self movieView] updateConstraints];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"VLCHUDModeChanged" object:nil];
}

- (IBAction)toggleHUDVisibility:(id)sender {
    self.hudVisibility = !self.hudVisibility;
}

- (IBAction)dismiss:(id)sender {
    [self.navigationController popViewControllerAnimated:_wasPushedAnimated];
}

- (IBAction)switchTrack:(id)sender {
    if([_mediaPlayer isVideoRecording]){
        [_mediaPlayer stopVideoRecord];
    }else{
        // 获取沙盒目录
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        // 输出沙盒目录
        NSLog(@"文件存储的目录是：%@",documentsDirectory);
        // 得到文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 如果YYTPlayer目录已经存在则直接写入目录，否则创建一个目录
        NSString *myDirectory = [documentsDirectory stringByAppendingPathComponent:@"YYTPlayer"];
        if ([fileManager fileExistsAtPath:myDirectory])
        {
            [_mediaPlayer saveVideoRecordAt:myDirectory];
        }else
        {
            // 创建目录成功则写入数据，否则打印错误
            BOOL createOK = [fileManager createDirectoryAtPath:myDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            if(createOK)
            {
                [_mediaPlayer saveVideoRecordAt:myDirectory];
            }else
            {
                NSLog(@"创建YYTPlayer目录失败，无法写入数据！");
            }
        }
    }
//    // 获取沙盒目录
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    // 输出沙盒目录
//    NSLog(@"文件存储的目录是：%@",documentsDirectory);
//    // 得到文件管理器
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    // 如果YYTPlayer目录已经存在则直接写入目录，否则创建一个目录
//    NSString *myDirectory = [documentsDirectory stringByAppendingPathComponent:@"YYTPlayer"];
//    if ([fileManager fileExistsAtPath:myDirectory])
//    {
//        [_mediaPlayer saveVideoSnapshotAt:myDirectory withWidth:352 andHeight:288];
//    }else
//    {
//        // 创建目录成功则写入数据，否则打印错误
//        BOOL createOK = [fileManager createDirectoryAtPath:myDirectory withIntermediateDirectories:YES attributes:nil error:nil];
//        if(createOK)
//        {
//            [_mediaPlayer saveVideoSnapshotAt:myDirectory withWidth:352 andHeight:288];
//        }else
//        {
//            NSLog(@"创建YYTPlayer目录失败，无法写入数据！");
//        }
//    }   
    
//    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose Audio Track", @"audio track selector") delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles: nil];
//    NSArray * audioTracks = [_mediaPlayer audioTracks];
//    NSUInteger count = [audioTracks count];
//    for (NSUInteger i = 1; i < count; i++) { // skip the "Disable menu item"
//        [actionSheet addButtonWithTitle:[audioTracks objectAtIndex:i]];
//    }
//    [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"audio track selector")];
//    [actionSheet setCancelButtonIndex:[actionSheet numberOfButtons] - 1];
//    [actionSheet showFromRect:[_trackSelectorButton frame] inView:_trackSelectorButton animated:YES];
//    [actionSheet autorelease];
}

#pragma mark -
#pragma mark UIViewAnimationDelegate
- (void)animationWillStart:(NSString *)animationID context:(void *)context {
    if ([animationID isEqualToString:MVLCMovieViewControllerHUDFadeInAnimation]) {
        self.HUDView.hidden = NO;
        self.topView.hidden = NO;
    }
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([animationID isEqualToString:MVLCMovieViewControllerHUDFadeOutAnimation] && [finished boolValue] == YES) {
        self.HUDView.hidden = YES;
        self.topView.hidden = YES;
    }
}

#pragma mark -
#pragma mark VLCMediaPlayerDelegate
- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {
    self.positionSlider.value = [_mediaPlayer position];
    self.remainingTimeLabel.title = [[_mediaPlayer remainingTime] stringValue];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification {
    VLCMediaPlayerState state = [_mediaPlayer state];

    if (state == VLCMediaPlayerStateError) {
        NSLog(@"VLCMediaPlayerStateError occured during playback");
        [self dismiss:nil];
    }
    if (state == VLCMediaPlayerStateStopped) {
        MVLCLog(@"input stopped!");
    }
    if (state == VLCMediaPlayerStateEnded) {
        MVLCLog(@"input ended!");
    }
    if (state == VLCMediaPlayerStateOpening) {
        MVLCLog(@"opening");
    }
    if (state == VLCMediaPlayerStatePlaying) {
        MVLCLog(@"input playing");
    }

    UIImage *playPauseImage = nil;
    if (state == VLCMediaPlayerStatePaused) {
        MVLCLog(@"input paused");
        playPauseImage = [UIImage imageNamed:@"MVLCMovieViewHUDPlay.png"];
    } else {
        playPauseImage = [UIImage imageNamed:@"MVLCMovieViewHUDPause.png"];
    }

    BOOL isActive = (state == VLCMediaPlayerStatePlaying
                     || state == VLCMediaPlayerStateOpening
                     || state == VLCMediaPlayerStateBuffering);
    [UIApplication sharedApplication].idleTimerDisabled = isActive;

    [self.playOrPauseButton setImage:playPauseImage forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // "Cancel" button
        [self dismiss:self];
    } else { // "Try anyway" button
        [_mediaPlayer play];
    }
}

#pragma mark -
#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // "Cancel" button
        MVLCLog(@"action sheet was canceled");
        return;
    }
    [_mediaPlayer setCurrentAudioTrackIndex: buttonIndex];
}

#pragma mark - external display

- (BOOL)hasExternalDisplay {
    return ([[UIScreen screens] count] > 1);
}

- (void)showOnExternalDisplay {
    UIScreen *screen = [[UIScreen screens] objectAtIndex:1];
    screen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;

    self.externalWindow = [[[UIWindow alloc] initWithFrame:screen.bounds] autorelease];
    UIViewController *controller = [[[ExternalDisplayController alloc] init] autorelease];
    self.externalWindow.rootViewController = controller;
    [controller.view addSubview:_movieView];
    controller.view.frame = screen.bounds;
    _movieView.frame = screen.bounds;
    self.playingExternallyView.hidden = NO;

    self.externalWindow.screen = screen;
    self.externalWindow.hidden = NO;
}

- (void)hideFromExternalDisplay {
    [self.view addSubview:_movieView];
    [self.view sendSubviewToBack:_movieView];
    _movieView.frame = self.view.frame;
    self.playingExternallyView.hidden = YES;

    self.externalWindow.hidden = YES;
    self.externalWindow = nil;
}

- (void)handleExternalScreenDidConnect:(NSNotification *)notification {
    [self showOnExternalDisplay];
}

- (void)handleExternalScreenDidDisconnect:(NSNotification *)notification {
    [self hideFromExternalDisplay];
}

@end
